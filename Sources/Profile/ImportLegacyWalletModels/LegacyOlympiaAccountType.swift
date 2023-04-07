import Prelude

// MARK: - LegacyOlympiaAccountType
public enum LegacyOlympiaAccountType: String, Sendable, Hashable, Codable, CustomStringConvertible {
	case software = "S"
	case hardware = "H"
	public var description: String {
		switch self {
		case .software: return "software"
		case .hardware: return "hardware"
		}
	}
}
