import CasePaths
import Prelude

extension PersonaData {
	public struct PhoneNumber: Sendable, Hashable, Codable, PersonaDataEntryProtocol {
		public static var casePath: CasePath<PersonaData.Entry, Self> = /PersonaData.Entry.phoneNumber
		public static var kind = PersonaData.Entry.Kind.phoneNumber

		public let number: String

		public init(number: String) {
			self.number = number
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(number)
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			try self.init(
				number: container.decode(String.self)
			)
		}
	}
}
