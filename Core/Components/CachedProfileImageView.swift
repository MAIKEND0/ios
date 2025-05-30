// Core/Components/CachedProfileImageView.swift
import SwiftUI
import Combine
import PhotosUI

/// Uniwersalny komponent do wyświetlania cache'owanych zdjęć profilowych
struct CachedProfileImageView: View {
    let employeeId: String
    let userType: UserType
    let currentImageUrl: String?
    let size: CGFloat
    let forceRefresh: Bool
    
    @State private var cachedImage: UIImage?
    @State private var isLoading: Bool = false
    @State private var cancellable: AnyCancellable?
    
    private let imageCache = ProfileImageCache.shared
    
    init(
        employeeId: String,
        userType: UserType,
        currentImageUrl: String?,
        size: CGFloat = 80,
        forceRefresh: Bool = false
    ) {
        self.employeeId = employeeId
        self.userType = userType
        self.currentImageUrl = currentImageUrl
        self.size = size
        self.forceRefresh = forceRefresh
    }
    
    var body: some View {
        Group {
            if let image = cachedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: size, height: size)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.ksrSecondary)
                    .frame(width: size, height: size)
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: currentImageUrl) { _, _ in
            loadImage()
        }
        .onChange(of: forceRefresh) { _, _ in
            if forceRefresh {
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        // Jeśli nie ma URL, nie ładuj
        guard let url = currentImageUrl, !url.isEmpty else {
            cachedImage = nil
            isLoading = false
            return
        }
        
        isLoading = true
        
        cancellable = imageCache.getProfileImage(
            employeeId: employeeId,
            userType: userType,
            currentImageUrl: currentImageUrl,
            forceRefresh: forceRefresh
        )
        .receive(on: DispatchQueue.main)
        .sink { image in
            self.cachedImage = image
            self.isLoading = false
        }
    }
}

// MARK: - Specialized Profile Picture Components

/// Komponent zdjęcia profilowego dla Worker
struct WorkerCachedProfileImage: View {
    let employeeId: String
    let currentImageUrl: String?
    let size: CGFloat
    let forceRefresh: Bool
    
    init(
        employeeId: String,
        currentImageUrl: String?,
        size: CGFloat = 80,
        forceRefresh: Bool = false
    ) {
        self.employeeId = employeeId
        self.currentImageUrl = currentImageUrl
        self.size = size
        self.forceRefresh = forceRefresh
    }
    
    var body: some View {
        CachedProfileImageView(
            employeeId: employeeId,
            userType: .worker,
            currentImageUrl: currentImageUrl,
            size: size,
            forceRefresh: forceRefresh
        )
    }
}

/// Komponent zdjęcia profilowego dla Manager
struct ManagerCachedProfileImage: View {
    let employeeId: String
    let currentImageUrl: String?
    let size: CGFloat
    let forceRefresh: Bool
    
    init(
        employeeId: String,
        currentImageUrl: String?,
        size: CGFloat = 80,
        forceRefresh: Bool = false
    ) {
        self.employeeId = employeeId
        self.currentImageUrl = currentImageUrl
        self.size = size
        self.forceRefresh = forceRefresh
    }
    
    var body: some View {
        CachedProfileImageView(
            employeeId: employeeId,
            userType: .manager,
            currentImageUrl: currentImageUrl,
            size: size,
            forceRefresh: forceRefresh
        )
    }
}

/// Komponent zdjęcia profilowego dla Supervisor
struct SupervisorCachedProfileImage: View {
    let employeeId: String
    let currentImageUrl: String?
    let size: CGFloat
    let forceRefresh: Bool
    
    init(
        employeeId: String,
        currentImageUrl: String?,
        size: CGFloat = 80,
        forceRefresh: Bool = false
    ) {
        self.employeeId = employeeId
        self.currentImageUrl = currentImageUrl
        self.size = size
        self.forceRefresh = forceRefresh
    }
    
    var body: some View {
        CachedProfileImageView(
            employeeId: employeeId,
            userType: .supervisor,
            currentImageUrl: currentImageUrl,
            size: size,
            forceRefresh: forceRefresh
        )
    }
}

// MARK: - Interactive Profile Picture Component

/// Komponent zdjęcia profilowego z możliwością edycji
struct InteractiveProfilePictureView<ViewModel: ProfilePictureUploadable>: View {
    @ObservedObject var viewModel: ViewModel
    let employeeId: String
    let userType: UserType
    let size: CGFloat
    let showEditControls: Bool
    
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var forceRefresh = false
    
    init(
        viewModel: ViewModel,
        employeeId: String,
        userType: UserType,
        size: CGFloat = 80,
        showEditControls: Bool = true
    ) {
        self.viewModel = viewModel
        self.employeeId = employeeId
        self.userType = userType
        self.size = size
        self.showEditControls = showEditControls
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.ksrLightGray)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.ksrYellow, lineWidth: 2)
                )
            
            CachedProfileImageView(
                employeeId: employeeId,
                userType: userType,
                currentImageUrl: viewModel.profilePictureUrl,
                size: size - 5,
                forceRefresh: forceRefresh
            )
            
            // Edit controls overlay
            if showEditControls {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: size * 0.25))
                                .foregroundColor(.ksrPrimary)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .offset(x: -4, y: -4)
                    }
                }
                .frame(width: size, height: size)
            }
            
            // Upload progress overlay
            if viewModel.isUploadingImage {
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: size, height: size)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            }
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedItem) {
            Task {
                if let currentItem = selectedItem {
                    do {
                        if let data = try await currentItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            
                            await MainActor.run {
                                viewModel.uploadProfilePicture(image)
                                
                                // Po upload, oznacz cache jako zaktualizowany
                                ProfileImageCache.shared.markImageAsUpdated(
                                    employeeId: employeeId,
                                    userType: userType,
                                    newImageUrl: viewModel.profilePictureUrl
                                )
                                
                                // Force refresh po małej chwili
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    forceRefresh.toggle()
                                }
                            }
                        }
                    } catch {
                        await MainActor.run {
                            viewModel.showError("Error loading image: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        .contextMenu {
            if viewModel.profilePictureUrl != nil {
                Button(role: .destructive) {
                    viewModel.deleteProfilePicture()
                    
                    // Usuń z cache
                    ProfileImageCache.shared.removeProfileImage(
                        employeeId: employeeId,
                        userType: userType
                    )
                    
                    // Force refresh
                    forceRefresh.toggle()
                } label: {
                    Label("Remove Picture", systemImage: "trash")
                }
            }
            
            Button {
                forceRefresh.toggle()
            } label: {
                Label("Refresh Picture", systemImage: "arrow.clockwise")
            }
        }
    }
}

// MARK: - Protocol for ViewModels

/// Protocol dla ViewModels które obsługują upload zdjęć profilowych
protocol ProfilePictureUploadable: ObservableObject {
    var profilePictureUrl: String? { get }
    var isUploadingImage: Bool { get }
    
    func uploadProfilePicture(_ image: UIImage)
    func deleteProfilePicture()
    func showError(_ message: String)
}

// MARK: - Preview

struct CachedProfileImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Basic cached image
            CachedProfileImageView(
                employeeId: "123",
                userType: .worker,
                currentImageUrl: "https://example.com/image.jpg",
                size: 80
            )
            
            // Different sizes
            HStack(spacing: 16) {
                CachedProfileImageView(
                    employeeId: "123",
                    userType: .manager,
                    currentImageUrl: nil,
                    size: 40
                )
                
                CachedProfileImageView(
                    employeeId: "456",
                    userType: .supervisor,
                    currentImageUrl: nil,
                    size: 60
                )
                
                CachedProfileImageView(
                    employeeId: "789",
                    userType: .worker,
                    currentImageUrl: nil,
                    size: 100
                )
            }
        }
        .padding()
    }
}
