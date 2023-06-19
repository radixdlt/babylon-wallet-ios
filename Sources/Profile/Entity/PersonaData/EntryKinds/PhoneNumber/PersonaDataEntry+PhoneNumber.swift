import CasePaths
import Prelude

extension PersonaDataEntry {
	public struct PhoneNumber: Sendable, Hashable, Codable, PersonaFieldValueProtocol {
		public static var casePath: CasePath<PersonaDataEntry, Self> = /PersonaDataEntry.phoneNumber
		public static var kind = PersonaFieldKind.phoneNumber

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
