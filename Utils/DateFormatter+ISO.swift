import Foundation

extension DateFormatter {
  /// Format yyyy-MM-dd
  static let isoDate: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd"
    df.locale = Locale(identifier: "en_US_POSIX")
    return df
  }()

  /// Format HH:mm
  static let time: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .none
    df.timeStyle = .short
    return df
  }()

  /// Format ISO8601 with fractional seconds: yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX
  static let iso8601WithFractions: DateFormatter = {
    let df = DateFormatter()
    df.calendar = Calendar(identifier: .iso8601)
    df.locale = Locale(identifier: "en_US_POSIX")
    df.timeZone = TimeZone(secondsFromGMT: 0)
    df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    return df
  }()

  /// User-friendly date format: e.g., "December 25, 2024"
  static let userFriendly: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .long
    df.timeStyle = .none
    df.locale = Locale(identifier: "en_US")
    return df
  }()

}
