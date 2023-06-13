import CasePaths
import EngineToolkit
import Prelude

// MARK: - TrustedContactFactorSource
public struct TrustedContactFactorSource: FactorSourceProtocol {
	public typealias ID = FactorSourceID.FromAddress

	public let id: ID
	public var common: FactorSource.Common
	public let emailAddress: EmailAddress
	public let name: NonEmptyString

	internal init(
		id: ID,
		common: FactorSource.Common,
		emailAddress: EmailAddress,
		name: NonEmptyString
	) {
		precondition(id.kind == Self.kind)
		self.id = id
		self.common = common
		self.emailAddress = emailAddress
		self.name = name
	}
}

extension TrustedContactFactorSource {
	public static let kind: FactorSourceKind = .trustedContact
	public static var casePath: CasePath<FactorSource, Self> = /FactorSource.trustedContact
}

extension TrustedContactFactorSource {
	public static func from(
		radixAddress: AccountAddress,
		emailAddress: EmailAddress,
		name: NonEmptyString,
		addedOn: Date? = nil,
		lastUsedOn: Date? = nil
	) -> Self {
		@Dependency(\.date) var date
		return Self(
			id: .init(kind: .trustedContact, body: radixAddress),
			common: .init(
				addedOn: addedOn ?? date(),
				lastUsedOn: lastUsedOn ?? date()
			),
			emailAddress: emailAddress,
			name: name
		)
	}
}

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
