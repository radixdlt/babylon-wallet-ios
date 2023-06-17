import CasePaths
import Prelude

// MARK: - PersonaDataEntry.PostalAddress
extension PersonaDataEntry {
	public struct PostalAddress: Sendable, Hashable, Codable, PersonaFieldValueProtocol {
		public static var casePath: CasePath<PersonaDataEntry, Self> = /PersonaDataEntry.postalAddress
		public static var kind = PersonaFieldKind.postalAddress

		public let fields: IdentifiedArrayOf<PersonaDataEntry.PostalAddress.Field>

		public init(unchecked fields: IdentifiedArrayOf<PersonaDataEntry.PostalAddress.Field>) {
			self.fields = fields
		}

		var country: Country? {
			fields.compactMap(\.country).first
		}

		public init(validating fields: IdentifiedArrayOf<PersonaDataEntry.PostalAddress.Field>) throws {
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
	}
}

extension PersonaDataEntry.PostalAddress.Field {
	var country: PersonaDataEntry.PostalAddress.Country? {
		switch self {
		case let .country(country): return country
		default: return nil
		}
	}
}
