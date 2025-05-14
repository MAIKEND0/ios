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
}
