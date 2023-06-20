import CasePaths
import Prelude

// MARK: - PersonaData.PostalAddress
extension PersonaData {
	public struct PostalAddress: Sendable, Hashable, Codable, PersonaDataEntryProtocol {
		public static var casePath: CasePath<PersonaData.Entry, Self> = /PersonaData.Entry.postalAddress
		public static var kind = PersonaData.Entry.Kind.postalAddress

		public let fields: IdentifiedArrayOf<PersonaData.PostalAddress.Field>

		public init(unchecked fields: IdentifiedArrayOf<PersonaData.PostalAddress.Field>) {
			self.fields = fields
		}

		var country: Country? {
			fields.compactMap(\.country).first
		}

		public init(validating fields: IdentifiedArrayOf<PersonaData.PostalAddress.Field>) throws {
			guard let country = fields.compactMap(\.country).first else {
				throw Error.noCountry
			}
			let discriminators = fields.map(\.discriminator)
			guard Set(discriminators) == Set(country.fields.flatMap { $0 }) else {
				throw Error.missingRequiredField
			}
			self.init(unchecked: fields)
		}

		public enum Error: Swift.Error {
			case noCountry
			case missingRequiredField
		}

		public init(from decoder: Decoder) throws {
			var container = try decoder.singleValueContainer()
			try self.init(validating: container.decode(IdentifiedArrayOf<PersonaData.PostalAddress.Field>.self))
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(fields.elements)
		}
	}
}

extension PersonaData.PostalAddress.Field {
	var country: PersonaData.PostalAddress.Country? {
		switch self {
		case let .country(country): return country
		default: return nil
		}
	}
}
