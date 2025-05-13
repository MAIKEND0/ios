//
//  AuthService.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import Foundation
import Combine

// Struktury DTO (Data Transfer Object) używane przez AuthService
struct LoginCredentials: Codable {
    let email: String
    let password: String // Hasło powinno być zawsze wysyłane przez HTTPS
}

struct AuthResponse: Codable {
    let token: String
    let employeeId: String
    let name: String
    let role: String
    // Możesz dodać inne pola zwracane przez Twoje API po zalogowaniu
}

class AuthService {
    static let shared = AuthService()
    
    private let baseURL: String
    private let session: URLSession
    
    private init() {
        // Ładowanie konfiguracji baseURL
        // Upewnij się, że masz jedną, poprawną definicję `Configuration` w projekcie
        self.baseURL = Configuration.apiBaseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30 // sekundy
        session = URLSession(configuration: config)
    }
    
    /// Logowanie użytkownika
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, APIError> {
        let credentials = LoginCredentials(email: email, password: password)
        
        // Upewnij się, że endpoint "/auth/login" jest poprawny dla Twojego API
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            // Możesz ustawić strategię kodowania daty, jeśli credentials tego wymagają
            // encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(credentials)
        } catch {
            // Błąd podczas kodowania credentials do JSON
            return Fail(error: APIError.decodingError(error)).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .mapError { urlError -> APIError in
                // Błąd na poziomie URLSession (np. brak połączenia z siecią)
                return APIError.networkError(urlError)
            }
            .flatMap { data, response -> AnyPublisher<Data, APIError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.invalidResponse).eraseToAnyPublisher()
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    // Sukces
                    return Just(data)
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                } else {
                    // Błąd serwera (np. 401 Unauthorized, 400 Bad Request, 500 Internal Server Error)
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Nieznany błąd serwera podczas logowania"
                    return Fail(error: APIError.serverError(httpResponse.statusCode, errorMessage))
                        .eraseToAnyPublisher()
                }
            }
            .decode(type: AuthResponse.self, decoder: JSONDecoder()) // Dekodowanie odpowiedzi JSON do AuthResponse
            .mapError { error -> APIError in
                // Mapowanie błędów dekodowania lub innych, które mogły się pojawić
                if let apiError = error as? APIError {
                    return apiError // Jeśli to już jest APIError (np. z flatMap)
                } else if let decodingError = error as? DecodingError {
                    print("AuthService - Błąd dekodowania AuthResponse: \(decodingError)")
                    return .decodingError(decodingError)
                } else {
                    // Inny nieoczekiwany błąd
                    return .networkError(error) // Lub .unknown, jeśli bardziej pasuje
                }
            }
            .handleEvents(receiveOutput: { authResponse in
                // Po pomyślnym zalogowaniu i zdekodowaniu odpowiedzi:
                // 1. Ustaw token w APIService, aby był używany w kolejnych żądaniach
                APIService.shared.authToken = authResponse.token
                
                // 2. Zapisz dane autoryzacyjne (token i inne informacje o użytkowniku)
                self.saveAuthData(authResponse)
            })
            .eraseToAnyPublisher()
    }
    
    /// Zapisuje dane autoryzacyjne.
    /// UWAGA: Poniższa implementacja dla tokenu używa UserDefaults jako PLACEHOLDERA.
    /// W aplikacji produkcyjnej ZDECYDOWANIE użyj Keychain Services API do bezpiecznego przechowywania tokenu.
    private func saveAuthData(_ authData: AuthResponse) {
        // Próba zapisu tokenu do "Keychain" (obecnie placeholderem jest UserDefaults)
        if storeInKeychainPlaceholder(key: "auth_token", data: authData.token) != nil {
            print("AuthService: Token zapisany (placeholder via UserDefaults). PAMIĘTAJ O PRAWDZIWYM KEYCHAIN!")
        } else {
            print("AuthService: Błąd zapisu tokenu (placeholder via UserDefaults).")
        }
        
        // Pozostałe dane można przechowywać w UserDefaults, jeśli nie są skrajnie wrażliwe,
        // lub również przenieść do Keychain, jeśli polityka bezpieczeństwa tego wymaga.
        UserDefaults.standard.set(authData.employeeId, forKey: "employee_id")
        UserDefaults.standard.set(authData.name, forKey: "employee_name")
        UserDefaults.standard.set(authData.role, forKey: "employee_role")
    }
    
    /// PLACEHOLDER: Funkcja pomocnicza do zapisu w "KeyChain" (aktualnie używa UserDefaults).
    /// Zastąp rzeczywistą implementacją Keychain Services.
    private func storeInKeychainPlaceholder(key: String, data: String) -> String? {
        UserDefaults.standard.set(data, forKey: key)
        // W prawdziwej implementacji Keychain, operacja zapisu może się nie udać,
        // więc zwracanie String? lub Bool jest dobrym pomysłem.
        // Tutaj, dla uproszczenia z UserDefaults, zakładamy sukces.
        return UserDefaults.standard.string(forKey: key) == data ? data : nil
    }
    
    /// Odczytuje zapisany token.
    /// UWAGA: Odczyt z UserDefaults (placeholder dla Keychain). Zastąp rzeczywistą implementacją Keychain.
    func getSavedToken() -> String? {
        // W prawdziwej implementacji, użyj KeyChain Services API do odczytu
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    /// Odczytuje ID zalogowanego pracownika.
    func getEmployeeId() -> String? {
        return UserDefaults.standard.string(forKey: "employee_id")
    }

    /// Odczytuje nazwę zalogowanego pracownika.
    func getEmployeeName() -> String? {
        return UserDefaults.standard.string(forKey: "employee_name")
    }

    /// Odczytuje rolę zalogowanego pracownika.
    func getEmployeeRole() -> String? {
        return UserDefaults.standard.string(forKey: "employee_role")
    }
    
    /// Wylogowuje użytkownika.
    func logout() {
        // 1. Usuń token z APIService
        APIService.shared.authToken = nil
        
        // 2. Usuń dane z miejsca ich przechowywania (obecnie UserDefaults, docelowo Keychain dla tokenu)
        // W prawdziwej implementacji, użyj KeyChain Services API do usunięcia tokenu.
        UserDefaults.standard.removeObject(forKey: "auth_token") // Placeholder for Keychain removal
        print("AuthService: Token usunięty (placeholder via UserDefaults). PAMIĘTAJ O PRAWDZIWYM KEYCHAIN!")
        
        UserDefaults.standard.removeObject(forKey: "employee_id")
        UserDefaults.standard.removeObject(forKey: "employee_name")
        UserDefaults.standard.removeObject(forKey: "employee_role")
        
        // Możesz tutaj wysłać powiadomienie (Notification) do reszty aplikacji,
        // że użytkownik się wylogował, aby UI mogło odpowiednio zareagować (np. przejść do ekranu logowania).
        // NotificationCenter.default.post(name: .didLogoutUser, object: nil)
    }
    
    /// Sprawdza czy użytkownik jest zalogowany (na podstawie obecności zapisanego tokenu).
    var isLoggedIn: Bool {
        if let token = getSavedToken() {
            // Jeśli token istnieje, ustaw go również w APIService na wypadek,
            // gdyby aplikacja została ponownie uruchomiona.
            // APIService również próbuje załadować token w swoim init(), co jest dobre.
            // Ta linia zapewnia dodatkową spójność.
            if APIService.shared.authToken == nil {
                 APIService.shared.authToken = token
            }
            return true
        }
        return false
    }
}

// Jeśli używasz powiadomień, możesz zdefiniować nazwę np. tak:
/*
extension Notification.Name {
    static let didLogoutUser = Notification.Name("didLogoutUser")
}
*/
