import CasePaths
import Prelude

// MARK: - PersonaData.PostalAddress
extension PersonaData {
	public struct PostalAddress: Sendable, Hashable, Codable, PersonaDataEntryProtocol, CustomStringConvertible {
		public static var casePath: CasePath<PersonaData.Entry, Self> = /PersonaData.Entry.postalAddress
		public static var kind = PersonaData.Entry.Kind.postalAddress

		public let fields: IdentifiedArrayOf<PersonaData.PostalAddress.Field>

		public init(unchecked fields: IdentifiedArrayOf<PersonaData.PostalAddress.Field>) {
			self.fields = fields
		}

		public var countryOrRegion: CountryOrRegion? {
			fields.compactMap(\.countryOrRegion).first
		}

		public init(validating fields: IdentifiedArrayOf<PersonaData.PostalAddress.Field>) throws {
			guard let countryOrRegion = fields.compactMap(\.countryOrRegion).first else {
				throw Error.noCountry
			}
			let discriminators = fields.map(\.discriminator)
			guard Set(discriminators) == Set(countryOrRegion.fields.flatMap { $0 }) else {
				throw Error.missingRequiredField
			}
			self.init(unchecked: fields)
		}

		public enum Error: Swift.Error {
			case noCountry
			case missingRequiredField
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			try self.init(validating: container.decode(IdentifiedArrayOf<PersonaData.PostalAddress.Field>.self))
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(fields.elements)
		}

		public var description: String {
			fields.map(\.valueAsString).joined(separator: ", ")
		}
	}
}

extension PersonaData.PostalAddress.Field {
	var countryOrRegion: PersonaData.PostalAddress.CountryOrRegion? {
		switch self {
		case let .countryOrRegion(countryOrRegion): return countryOrRegion
		default: return nil
		}
	}
}
