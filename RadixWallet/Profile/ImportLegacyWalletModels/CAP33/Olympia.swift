// MARK: - Olympia
public enum Olympia {}

// MARK: Olympia.AccountType
extension Olympia {
	public enum AccountType: String, Sendable, Hashable, CustomStringConvertible {
		case software = "S"
		case hardware = "H"
		public var description: String {
			switch self {
			case .software: "software"
			case .hardware: "hardware"
			}
		}
	}
}
