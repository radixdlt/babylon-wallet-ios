import CasePaths
import Prelude

// MARK: - PersonaFieldValue.PostalAddress
extension PersonaFieldValue {
	public struct PostalAddress: Sendable, Hashable, Codable, PersonaFieldValueProtocol {
		public static var casePath: CasePath<PersonaFieldValue, Self> = /PersonaFieldValue.postalAddress
		public static var kind = PersonaFieldKind.postalAddress

		public var fields: IdentifiedArrayOf<PersonaFieldValue.PostalAddress.Field>
		public init(unchecked fields: IdentifiedArrayOf<PersonaFieldValue.PostalAddress.Field>) {
			self.fields = fields
		}

		public init(validating fields: IdentifiedArrayOf<PersonaFieldValue.PostalAddress.Field>) throws {
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

extension PersonaFieldValue.PostalAddress.Field {
	var country: PersonaFieldValue.PostalAddress.Country? {
		switch self {
		case let .county(countryString): return .init(rawValue: countryString)
		default: return nil
		}
	}
}
