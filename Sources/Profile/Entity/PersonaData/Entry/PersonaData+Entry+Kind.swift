import Foundation

// MARK: - PersonaData.Entry.Kind
extension PersonaData.Entry {
	public enum Kind: String, Sendable, Hashable, Codable {
		case name
		case dateOfBirth
		case companyName

		case emailAddress
		case url
		case phoneNumber
		case postalAddress
		case creditCard
	}
}
