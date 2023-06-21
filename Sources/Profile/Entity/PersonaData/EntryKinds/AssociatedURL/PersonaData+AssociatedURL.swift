import CasePaths
import Prelude

extension PersonaData {
	public struct AssociatedURL: Sendable, Hashable, Codable, PersonaDataEntryProtocol, CustomStringConvertible {
		public static var casePath: CasePath<PersonaData.Entry, Self> = /PersonaData.Entry.url
		public static var kind = PersonaData.Entry.Kind.url

		public let url: URL

		public init(validating urlString: String) throws {
			guard let url = URL(string: urlString) else {
				throw InvalidURL(invalid: urlString)
			}
			self.url = url
		}

		struct InvalidURL: Swift.Error {
			let invalid: String
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(url)
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			try self.init(validating: container.decode(String.self))
		}

		public var description: String {
			url.absoluteString
		}
	}
}
