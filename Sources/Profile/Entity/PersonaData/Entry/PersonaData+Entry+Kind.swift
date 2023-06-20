import Foundation

// MARK: - PersonaData.Entry.Kind
extension PersonaData.Entry {
	public enum Kind: String, Sendable, Hashable, Codable {
		case name
		case emailAddress
		case dateOfBirth
		case postalAddress
		case phoneNumber
		case creditCard
		case companyName
	}
}
