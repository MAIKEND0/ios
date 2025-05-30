// Core/Cache/ProfileImageCache.swift
import UIKit
import Foundation
import Combine

/// Uniwersalny system cachowania zdjęć profilowych
final class ProfileImageCache {
    static let shared = ProfileImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let userDefaults = UserDefaults.standard
    
    // Key do przechowywania ostatniego timestamp aktualizacji zdjęcia
    private func lastUpdateKey(for employeeId: String, userType: String) -> String {
        return "profile_image_last_update_\(userType)_\(employeeId)"
    }
    
    // Key do przechowywania URL zdjęcia
    private func imageUrlKey(for employeeId: String, userType: String) -> String {
        return "profile_image_url_\(userType)_\(employeeId)"
    }
    
    private init() {
        // Konfiguracja NSCache
        cache.countLimit = 50 // Maksymalnie 50 zdjęć w pamięci
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB w pamięci
        
        // Utworzenie katalogu cache na dysku
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("ProfileImageCache")
        
        // Tworzenie katalogu jeśli nie istnieje
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Czyszczenie starych plików przy starcie (opcjonalne)
        cleanOldCacheFiles()
    }
    
    // MARK: - Public Methods
    
    /// Pobiera zdjęcie z cache lub z API jeśli potrzebne
    func getProfileImage(
        employeeId: String,
        userType: UserType,
        currentImageUrl: String?,
        forceRefresh: Bool = false
    ) -> AnyPublisher<UIImage?, Never> {
        
        let cacheKey = "\(userType.rawValue)_\(employeeId)"
        
        // 🆕 POPRAWKA: Sprawdź czy mamy valid URL
        guard let imageUrl = currentImageUrl, !imageUrl.isEmpty else {
            #if DEBUG
            print("[ProfileImageCache] ❌ No valid image URL for \(cacheKey)")
            #endif
            return Just(nil).eraseToAnyPublisher()
        }
        
        // 1. Sprawdź czy mamy zdjęcie w pamięci i nie wymagamy odświeżenia
        if !forceRefresh,
           let cachedImage = cache.object(forKey: NSString(string: cacheKey)) {
            #if DEBUG
            print("[ProfileImageCache] 🎯 Image loaded from memory cache for \(cacheKey)")
            #endif
            return Just(cachedImage).eraseToAnyPublisher()
        }
        
        // 2. Sprawdź czy mamy zdjęcie na dysku i czy jest aktualne
        if !forceRefresh,
           let diskImage = loadImageFromDisk(employeeId: employeeId, userType: userType),
           !needsRefresh(employeeId: employeeId, userType: userType, currentUrl: currentImageUrl) {
               
            // Dodaj do cache w pamięci
            cache.setObject(diskImage, forKey: NSString(string: cacheKey))
            
            #if DEBUG
            print("[ProfileImageCache] 💾 Image loaded from disk cache for \(cacheKey)")
            #endif
            return Just(diskImage).eraseToAnyPublisher()
        }
        
        // 3. Pobierz z API
        guard let url = URL(string: imageUrl) else {
            #if DEBUG
            print("[ProfileImageCache] ❌ Invalid image URL for \(cacheKey): \(imageUrl)")
            #endif
            return Just(nil).eraseToAnyPublisher()
        }
        
        #if DEBUG
        print("[ProfileImageCache] 🌐 Downloading image from API for \(cacheKey) from URL: \(imageUrl)")
        #endif
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .compactMap { data -> UIImage? in
                return UIImage(data: data)
            }
            .handleEvents(receiveOutput: { [weak self] (image: UIImage?) in
                guard let self = self, let image = image else { return }
                // Cache w pamięci i na dysku
                self.cache.setObject(image, forKey: NSString(string: cacheKey))
                self.saveImageToDisk(image, employeeId: employeeId, userType: userType)
                self.updateCacheMetadata(employeeId: employeeId, userType: userType, imageUrl: imageUrl)
                
                #if DEBUG
                print("[ProfileImageCache] ✅ Successfully cached image for \(cacheKey)")
                #endif
            })
            .catch { error -> Just<UIImage?> in
                #if DEBUG
                print("[ProfileImageCache] ❌ Failed to download image for \(cacheKey): \(error)")
                #endif
                return Just(nil)
            }
            .eraseToAnyPublisher()
    }
    
    /// Oznacza że zdjęcie zostało zaktualizowane (wywołaj po upload)
    func markImageAsUpdated(employeeId: String, userType: UserType, newImageUrl: String?) {
        let timestampKey = lastUpdateKey(for: employeeId, userType: userType.rawValue)
        let urlKey = imageUrlKey(for: employeeId, userType: userType.rawValue)
        let cacheKey = "\(userType.rawValue)_\(employeeId)"
        
        // Zapisz nowy timestamp i URL
        userDefaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
        userDefaults.set(newImageUrl, forKey: urlKey)
        
        // Usuń z cache w pamięci - wymusi pobranie nowej wersji
        cache.removeObject(forKey: NSString(string: cacheKey))
        
        // Usuń z dysku
        removeImageFromDisk(employeeId: employeeId, userType: userType)
        
        #if DEBUG
        print("[ProfileImageCache] 🔄 Marked image as updated for \(cacheKey)")
        print("[ProfileImageCache] 🔄 New URL: \(newImageUrl ?? "nil")")
        #endif
        
        // 🆕 DODANE: Jeśli mamy nowy URL, od razu spróbuj go pobrać
        if let imageUrl = newImageUrl, !imageUrl.isEmpty {
            // Asynchronicznie pobierz nowe zdjęcie w tle
            _ = getProfileImage(
                employeeId: employeeId,
                userType: userType,
                currentImageUrl: imageUrl,
                forceRefresh: true
            )
            .sink { _ in
                // Nie robimy nic z rezultatem - po prostu chcemy załadować do cache
            }
        }
    }
    
    /// Usuwa zdjęcie z cache (wywołaj po delete)
    func removeProfileImage(employeeId: String, userType: UserType) {
        let cacheKey = "\(userType.rawValue)_\(employeeId)"
        
        // Usuń z pamięci
        cache.removeObject(forKey: NSString(string: cacheKey))
        
        // Usuń z dysku
        removeImageFromDisk(employeeId: employeeId, userType: userType)
        
        // Usuń metadata
        let timestampKey = lastUpdateKey(for: employeeId, userType: userType.rawValue)
        let urlKey = imageUrlKey(for: employeeId, userType: userType.rawValue)
        userDefaults.removeObject(forKey: timestampKey)
        userDefaults.removeObject(forKey: urlKey)
        
        #if DEBUG
        print("[ProfileImageCache] 🗑️ Removed profile image for \(cacheKey)")
        #endif
    }
    
    /// Czyści cały cache
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Usuń wszystkie metadata
        let keys = userDefaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix("profile_image_") }
        
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
        
        #if DEBUG
        print("[ProfileImageCache] 🧹 Cache cleared")
        #endif
    }
    
    // MARK: - Private Methods
    
    private func needsRefresh(employeeId: String, userType: UserType, currentUrl: String?) -> Bool {
        let timestampKey = lastUpdateKey(for: employeeId, userType: userType.rawValue)
        let urlKey = imageUrlKey(for: employeeId, userType: userType.rawValue)
        
        let lastUpdate = userDefaults.double(forKey: timestampKey)
        let cachedUrl = userDefaults.string(forKey: urlKey)
        
        // Jeśli URL się zmienił, potrzebujemy odświeżenia
        if cachedUrl != currentUrl {
            #if DEBUG
            print("[ProfileImageCache] 🔄 URL changed for \(userType.rawValue)_\(employeeId): \(cachedUrl ?? "nil") -> \(currentUrl ?? "nil")")
            #endif
            return true
        }
        
        // Jeśli nie ma zapisanego czasu aktualizacji, potrzebujemy odświeżenia
        if lastUpdate == 0 {
            #if DEBUG
            print("[ProfileImageCache] 🔄 No cached timestamp for \(userType.rawValue)_\(employeeId)")
            #endif
            return true
        }
        
        // 🆕 POPRAWKA: Skróć czas cache do 1 godziny dla bardziej aktualnych zdjęć
        let hoursSinceUpdate = (Date().timeIntervalSince1970 - lastUpdate) / 3600
        let needsRefresh = hoursSinceUpdate > 1 // Odświeżaj co godzinę
        
        #if DEBUG
        if needsRefresh {
            print("[ProfileImageCache] 🔄 Cache expired for \(userType.rawValue)_\(employeeId) (hours since update: \(String(format: "%.1f", hoursSinceUpdate)))")
        }
        #endif
        
        return needsRefresh
    }
    
    private func diskImagePath(employeeId: String, userType: UserType) -> URL {
        return cacheDirectory.appendingPathComponent("\(userType.rawValue)_\(employeeId).jpg")
    }
    
    private func loadImageFromDisk(employeeId: String, userType: UserType) -> UIImage? {
        let imagePath = diskImagePath(employeeId: employeeId, userType: userType)
        
        guard let imageData = try? Data(contentsOf: imagePath),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    private func saveImageToDisk(_ image: UIImage, employeeId: String, userType: UserType) {
        let imagePath = diskImagePath(employeeId: employeeId, userType: userType)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        do {
            try imageData.write(to: imagePath)
            #if DEBUG
            print("[ProfileImageCache] 💾 Saved image to disk for \(userType.rawValue)_\(employeeId)")
            #endif
        } catch {
            #if DEBUG
            print("[ProfileImageCache] ❌ Failed to save image to disk: \(error)")
            #endif
        }
    }
    
    private func removeImageFromDisk(employeeId: String, userType: UserType) {
        let imagePath = diskImagePath(employeeId: employeeId, userType: userType)
        try? fileManager.removeItem(at: imagePath)
    }
    
    private func updateCacheMetadata(employeeId: String, userType: UserType, imageUrl: String) {
        let timestampKey = lastUpdateKey(for: employeeId, userType: userType.rawValue)
        let urlKey = imageUrlKey(for: employeeId, userType: userType.rawValue)
        
        userDefaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
        userDefaults.set(imageUrl, forKey: urlKey)
        
        #if DEBUG
        print("[ProfileImageCache] 📝 Updated metadata for \(userType.rawValue)_\(employeeId)")
        #endif
    }
    
    private func cleanOldCacheFiles() {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 dni temu
        
        for file in files {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: file.path)
                if let creationDate = attributes[.creationDate] as? Date,
                   creationDate < sevenDaysAgo {
                    try fileManager.removeItem(at: file)
                    #if DEBUG
                    print("[ProfileImageCache] 🧽 Cleaned old cache file: \(file.lastPathComponent)")
                    #endif
                }
            } catch {
                // Ignoruj błędy czyszczenia
            }
        }
    }
    
    // 🆕 DODANA: Metoda do bezpośredniego dodania zdjęcia do cache (dla natychmiastowego UI update)
    func cacheImageDirectly(_ image: UIImage, employeeId: String, userType: UserType, imageUrl: String) {
        let cacheKey = "\(userType.rawValue)_\(employeeId)"
        
        // Dodaj do cache w pamięci
        cache.setObject(image, forKey: NSString(string: cacheKey))
        
        // Zapisz na dysku
        saveImageToDisk(image, employeeId: employeeId, userType: userType)
        
        // Zaktualizuj metadata
        updateCacheMetadata(employeeId: employeeId, userType: userType, imageUrl: imageUrl)
        
        #if DEBUG
        print("[ProfileImageCache] ⚡ Directly cached image for \(cacheKey)")
        #endif
    }
}

// MARK: - Supporting Types

enum UserType: String, CaseIterable {
    case worker = "worker"
    case supervisor = "supervisor"
    case manager = "manager"
}

// MARK: - Extension dla łatwego użycia w ViewModels

extension ProfileImageCache {
    /// Convenience method dla worker
    func getWorkerProfileImage(
        employeeId: String,
        currentImageUrl: String?,
        forceRefresh: Bool = false
    ) -> AnyPublisher<UIImage?, Never> {
        return getProfileImage(
            employeeId: employeeId,
            userType: .worker,
            currentImageUrl: currentImageUrl,
            forceRefresh: forceRefresh
        )
    }
    
    /// Convenience method dla supervisor
    func getSupervisorProfileImage(
        supervisorId: String,
        currentImageUrl: String?,
        forceRefresh: Bool = false
    ) -> AnyPublisher<UIImage?, Never> {
        return getProfileImage(
            employeeId: supervisorId,
            userType: .supervisor,
            currentImageUrl: currentImageUrl,
            forceRefresh: forceRefresh
        )
    }
}
