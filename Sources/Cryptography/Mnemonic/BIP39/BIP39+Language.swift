import Foundation

// MARK: - BIP39.Language
public extension BIP39 {
	enum Language: String, CaseIterable, CustomStringConvertible, Sendable, Hashable {
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

public extension BIP39.Language {
	static let `default` = Self.english
}

public extension BIP39.Language {
	var description: String {
		rawValue
	}
}
