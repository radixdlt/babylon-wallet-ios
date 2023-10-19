// MARK: - EmailAddress
public struct EmailAddress: Sendable, Hashable, Codable {
	public let email: NonEmptyString
	public init(validating email: NonEmptyString) throws {
		guard email.rawValue.isEmailAddress else {
			throw InvalidEmailAddress(invalid: email.rawValue)
		}
		self.email = email
	}

	struct InvalidEmailAddress: Swift.Error {
		let invalid: String
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(email.rawValue)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let emailMaybeEmpty = try container.decode(String.self)
		guard let nonEmpty = NonEmptyString(rawValue: emailMaybeEmpty) else {
			struct InvalidEmailAddressCannotBeEmpty: Swift.Error {}
			throw InvalidEmailAddressCannotBeEmpty()
		}
		try self.init(validating: nonEmpty)
	}
}
