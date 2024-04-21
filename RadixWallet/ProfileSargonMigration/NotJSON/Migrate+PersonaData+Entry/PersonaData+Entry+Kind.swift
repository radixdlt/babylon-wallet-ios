// MARK: - PersonaData.Entry.Kind
extension PersonaData.Entry {
	public enum Kind: String, Sendable, Hashable, Codable {
		case fullName
		case emailAddress
		case phoneNumber
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
			"Email Address"
		case .phoneNumber:
			"Phone Number"
		}
	}
}
