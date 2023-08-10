import Foundation
import Resources

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
			.phoneNumber,
			.emailAddress,
		]
	}

	public var title: String {
		switch self {
		case .fullName:
			return L10n.AuthorizedDapps.PersonaDetails.fullName
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
