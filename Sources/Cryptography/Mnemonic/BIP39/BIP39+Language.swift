import Foundation

// MARK: - BIP39.Language
extension BIP39 {
	public enum Language: String, CaseIterable, CustomStringConvertible, Sendable, Hashable {
		case english = "English"
		case japanese = "Japanese"
		case korean = "Korean"
		case spanish = "Spanish"
		case chineseSimplified = "Chinese Simplified"
		case chineseTraditional = "Chinese Traditional"
		case french = "French"
		case italian = "Italian"
	}
}

extension BIP39.Language {
	public static let `default` = Self.english
}

extension BIP39.Language {
	public var description: String {
		rawValue
	}
}
