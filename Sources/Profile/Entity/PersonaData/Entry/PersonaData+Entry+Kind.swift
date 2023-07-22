import Foundation

// MARK: - PersonaData.Entry.Kind
extension PersonaData.Entry {
	public enum Kind: String, Sendable, Hashable, Codable {
		case fullName
		case dateOfBirth
		case companyName

		case emailAddress
		case url
		case phoneNumber
		case postalAddress
		case creditCard
	}
}

extension PersonaData.Entry.Kind {
	public static var supportedKinds: [Self] {
		[
			.fullName,
			.emailAddress,
			.phoneNumber,
		]
	}

	public var title: String {
		switch self {
		case .fullName:
			return "Full Name"
		case .emailAddress:
			return "Email Address"
		case .phoneNumber:
			return "Phone Number"
		case .postalAddress:
			return "Postal Address"
		case .dateOfBirth:
			return "NA"
		case .companyName:
			return "NA"
		case .url:
			return "NA"
		case .creditCard:
			return "NA"
		}
	}
}
