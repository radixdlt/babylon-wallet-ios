import CasePaths
import Prelude

// MARK: - TrustedContactFactorSource
public struct TrustedContactFactorSource: FactorSourceProtocol {
	public typealias ID = FactorSourceID.FromAddress

	public let id: ID
	public var common: FactorSource.Common
	public let contact: Contact

	internal init(
		id: ID,
		common: FactorSource.Common,
		contact: Contact
	) {
		precondition(id.kind == Self.kind)
		self.id = id
		self.common = common
		self.contact = contact
	}
}

extension TrustedContactFactorSource {
	public static let kind: FactorSourceKind = .trustedContact
	public static var casePath: CasePath<FactorSource, Self> = /FactorSource.trustedContact
}

// MARK: TrustedContactFactorSource.Contact
extension TrustedContactFactorSource {
	public struct Contact: Sendable, Hashable, Codable {
		public let name: NonEmptyString
		public let email: EmailAddress
		public init(name: NonEmptyString, email: EmailAddress) {
			self.name = name
			self.email = email
		}
	}
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
			contact: .init(name: name, email: emailAddress)
		)
	}
}
