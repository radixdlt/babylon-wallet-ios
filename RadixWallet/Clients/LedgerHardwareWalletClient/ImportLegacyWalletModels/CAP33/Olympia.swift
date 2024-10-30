// MARK: - Olympia
enum Olympia {}

// MARK: Olympia.AccountType
extension Olympia {
	enum AccountType: String, Sendable, Hashable, CustomStringConvertible {
		case software = "S"
		case hardware = "H"
		var description: String {
			switch self {
			case .software: "software"
			case .hardware: "hardware"
			}
		}
	}
}
