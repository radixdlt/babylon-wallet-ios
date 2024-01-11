import EngineToolkit

extension PersonaData {
	public struct EmailAddress: Sendable, Hashable, Codable, PersonaDataEntryProtocol, CustomStringConvertible {
		public static var casePath: CasePath<PersonaData.Entry, Self> = /PersonaData.Entry.emailAddress
		public static var kind = PersonaData.Entry.Kind.emailAddress

		public let email: String

		public init(email: String) {
			self.email = email
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(email)
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			let email = try container.decode(String.self)
			self.init(email: email)
		}

		public var description: String {
			email
		}
	}
}
