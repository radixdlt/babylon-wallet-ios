

extension PersonaData {
	public struct AssociatedURL: Sendable, Hashable, Codable, PersonaDataEntryProtocol, CustomStringConvertible {
		public static var casePath: CasePath<PersonaData.Entry, Self> = /PersonaData.Entry.url
		public static var kind = PersonaData.Entry.Kind.url

		public let url: String

		public init(url: String) {
			self.url = url
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(url)
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			try self.init(url: container.decode(String.self))
		}

		public var description: String {
			url
		}
	}
}
