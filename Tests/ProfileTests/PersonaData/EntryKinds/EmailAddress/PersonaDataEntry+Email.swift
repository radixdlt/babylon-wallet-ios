import CasePaths
import Prelude

extension PersonaDataEntry {
	public struct EmailAddress: Sendable, Hashable, Codable, PersonaFieldValueProtocol {
		public static var casePath: CasePath<PersonaDataEntry, Self> = /PersonaDataEntry.emailAddress
		public static var kind = PersonaFieldKind.emailAddress

		public let email: String

		public init(validating email: String) throws {
			guard email.isEmailAddress else {
				throw InvalidEmailAddress(invalid: email)
			}
			self.email = email
		}

		struct InvalidEmailAddress: Swift.Error {
			let invalid: String
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(email)
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			try self.init(validating: container.decode(String.self))
		}
	}
}
