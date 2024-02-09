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
			L10n.AuthorizedDapps.PersonaDetails.fullName
		case .emailAddress:
			"Email RETAddress"
		case .phoneNumber:
			"Phone Number"
		case .postalAddress:
			"Postal RETAddress"
		case .dateOfBirth:
			"NA"
		case .companyName:
			"NA"
		case .url:
			"NA"
		case .creditCard:
			"NA"
		}
	}
}
