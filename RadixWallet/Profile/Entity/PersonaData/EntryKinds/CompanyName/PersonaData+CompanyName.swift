

extension PersonaData {
	public struct CompanyName: Sendable, Hashable, Codable, PersonaDataEntryProtocol, CustomStringConvertible {
		public static var casePath: CasePath<PersonaData.Entry, Self> = /PersonaData.Entry.companyName
		public static var kind = PersonaData.Entry.Kind.companyName

		public let name: String

		public init(name: String) {
			self.name = name
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(name)
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			try self.init(
				name: container.decode(String.self)
			)
		}

		public var description: String {
			name
		}
	}
}
