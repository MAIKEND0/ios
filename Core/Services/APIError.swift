//
//  APIError.swift
//  KSR Cranes App
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int, String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Niepoprawny adres URL"
        case .invalidResponse:      return "Niepoprawna odpowiedź serwera"
        case .networkError(let e):  return "Błąd sieci: \(e.localizedDescription)"
        case .decodingError(let e): return "Błąd dekodowania: \(e.localizedDescription)"
        case .serverError(let c, let m): return "Błąd serwera (\(c)): \(m)"
        case .unknown:              return "Nieznany błąd"
        }
    }
}
