//
//  APIService.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import Foundation
import Combine

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int, String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Niepoprawny adres URL"
        case .invalidResponse:
            return "Niepoprawna odpowiedź serwera"
        case .networkError(let error):
            return "Błąd sieci: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Błąd dekodowania: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Błąd serwera (\(code)): \(message)"
        case .unknown:
            return "Nieznany błąd"
        }
    }
}

class APIService {
    // Singleton instance dla łatwego dostępu
    static let shared = APIService()
    
    // Bazowy URL do API - pobierany z konfiguracji
    private let baseURL: String
    
    // Sesja URL używana do wykonywania żądań
    private let session: URLSession
    
    // Token autoryzacyjny - ustaw go po zalogowaniu
    var authToken: String?
    
    private init() {
        // Pobieranie konfiguracji z centralnego miejsca
        self.baseURL = Configuration.apiBaseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
        
        // Sprawdź czy jest zapisany token i użyj go
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            self.authToken = token
        }
    }
    
    // MARK: - Work Hours Endpoints
    
    /// Zapisuje draft wpisów godzin pracy
    func saveDraftWorkEntries(_ entries: [WorkHourEntry]) -> AnyPublisher<Bool, APIError> {
        let endpoint = "/work-entries/draft"
        
        // Dodajemy logowanie dla debugowania
        #if DEBUG
        print("Zapisywanie \(entries.count) wpisów wersji roboczej")
        #endif
        
        return makeRequest(
            endpoint: endpoint,
            method: "POST",
            body: ["entries": entries]
        )
        .map { _ in true }
        .eraseToAnyPublisher()
    }
    
    /// Wysyła zatwierdzone wpisy godzin pracy
    func submitWorkEntries(_ entries: [WorkHourEntry]) -> AnyPublisher<Bool, APIError> {
        let endpoint = "/work-entries/bulk"
        
        #if DEBUG
        print("Wysyłanie \(entries.count) zatwierdzonych wpisów")
        #endif
        
        return makeRequest(
            endpoint: endpoint,
            method: "POST",
            body: ["entries": entries]
        )
        .map { _ in true }
        .eraseToAnyPublisher()
    }
    
    /// Pobiera wpisy godzin pracy dla określonego pracownika i tygodnia
    func fetchWorkEntries(employeeId: String, weekStartDate: String) -> AnyPublisher<[WorkHourEntry], APIError> {
        let endpoint = "/work-entries?employee_id=\(employeeId)&selectedMonday=\(weekStartDate)"
        
        return makeRequest(
            endpoint: endpoint,
            method: "GET",
            body: Optional<String>.none
        )
        .decode(type: [WorkHourEntry].self, decoder: createJsonDecoder())
        .mapError { error in
            if let decodingError = error as? DecodingError {
                print("Błąd dekodowania: \(decodingError)")
                return .decodingError(decodingError)
            } else {
                return error as? APIError ?? .unknown
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Pobiera draft wpisów godzin pracy
    func fetchDraftWorkEntries(employeeId: String, weekStartDate: String) -> AnyPublisher<[WorkHourEntry], APIError> {
        let endpoint = "/work-entries/draft?employee_id=\(employeeId)&selectedMonday=\(weekStartDate)"
        
        return makeRequest(
            endpoint: endpoint,
            method: "GET",
            body: Optional<String>.none
        )
        .decode(type: [WorkHourEntry].self, decoder: createJsonDecoder())
        .mapError { error in
            if let decodingError = error as? DecodingError {
                print("Błąd dekodowania: \(decodingError)")
                return .decodingError(decodingError)
            } else {
                return error as? APIError ?? .unknown
            }
        }
        .eraseToAnyPublisher()
    }
    
    // Tworzenie dekodera JSON z odpowiednimi strategiami
    private func createJsonDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    // MARK: - Generic Request Method
    
    /// Generyczna metoda do wykonywania żądań HTTP
    private func makeRequest<T: Encodable>(
        endpoint: String,
        method: String,
        body: T?
    ) -> AnyPublisher<Data, APIError> {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Dodaj token jeśli jest dostępny
        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Dodaj body dla metod innych niż GET
        if method != "GET", let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(body)
            } catch {
                print("Błąd kodowania body: \(error)")
                return Fail(error: APIError.networkError(error)).eraseToAnyPublisher()
            }
        }
        
        #if DEBUG
        print("Wysyłanie żądania: \(method) \(url)")
        #endif
        
        return session.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<Data, APIError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.invalidResponse).eraseToAnyPublisher()
                }
                
                #if DEBUG
                print("Otrzymano odpowiedź: \(httpResponse.statusCode)")
                if let responseStr = String(data: data, encoding: .utf8) {
                    print("Treść: \(String(responseStr.prefix(200)))...")
                }
                #endif
                
                if (200...299).contains(httpResponse.statusCode) {
                    return Just(data)
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                } else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    return Fail(error: APIError.serverError(httpResponse.statusCode, errorMessage))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Mock Methods for Testing
    
    #if DEBUG
    /// Tworzy mockowe dane do testowania bez połączenia z serwerem
    func createMockData() -> [WorkHourEntry] {
        let calendar = Calendar.current
        let today = Date()
        let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        var entries: [WorkHourEntry] = []
        
        for i in 0..<5 {  // Poniedziałek-Piątek
            let currentDate = calendar.date(byAdding: .day, value: i, to: monday)!
            let entry = WorkHourEntry(
                id: "mock-\(i)",
                date: currentDate,
                startTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: currentDate),
                endTime: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: currentDate),
                projectId: "project-123",
                description: "Mockowe dane do testów #\(i+1)",
                employeeId: "emp-456",
                pauseMinutes: 30,
                status: .pending,
                isDraft: i % 2 == 0  // na zmianę draft/nie-draft
            )
            entries.append(entry)
        }
        
        return entries
    }
    #endif
}
