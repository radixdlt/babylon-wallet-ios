// MARK: - InitializableFromInputString
public protocol InitializableFromInputString: Sendable, Codable, Hashable {
	init?(_ input: String)
}

// MARK: - String + InitializableFromInputString
extension String: InitializableFromInputString {
	public init?(_ input: String) {
		self = input
	}
}

// MARK: - Int + InitializableFromInputString
extension Int: InitializableFromInputString {
	public init?(_ input: String) {
		guard let int = Self(input) else {
			return nil
		}
		self = int
	}
}

// MARK: - PersonaDataEntry.PostalAddress.Country + InitializableFromInputString
extension PersonaDataEntry.PostalAddress.Country: InitializableFromInputString {
	public init?(_ input: String) {
		guard let country = Self(rawValue: input) else {
			return nil
		}
		self = country
	}
}
