import CasePaths
import Prelude

// MARK: - EmailAddress
public struct EmailAddress: Sendable, Hashable, Codable {
	public let email: NonEmptyString
	public init(validating email: NonEmptyString) throws {
		self.email = email
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

// MARK: - TrustedContactFactorSource
public struct TrustedContactFactorSource: FactorSourceProtocol {
	public var common: FactorSource.Common
	public let emailAddress: EmailAddress
	public let name: NonEmptyString
}

extension TrustedContactFactorSource {
	public static let kind: FactorSourceKind = .trustedContact
	public static var casePath: CasePath<FactorSource, Self> = /FactorSource.trustedContact
}
