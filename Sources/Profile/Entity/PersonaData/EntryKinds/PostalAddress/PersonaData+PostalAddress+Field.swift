import Foundation

// MARK: - PersonaData.PostalAddress.Field
extension PersonaData.PostalAddress {
	public enum Field: Sendable, Hashable, Codable, Identifiable, CustomStringConvertible {
		public typealias ID = Discriminator
		public var id: ID {
			discriminator
		}

		case countryOrRegion(CountryOrRegion)
		case streetLine0(String)
		case streetLine1(String = "")

		case postalCode(String)

		case postcode(String)

		/// US
		case zip(String)

		case city(String)
		case state(String)

		/// Australia
		case suburb(String)

		/// Brazil
		case neighbourhood(String)

		/// Canada
		case province(String)

		/// Egypt
		case governorate(String)

		/// Hong Kong
		case district(String)

		/// Hong Kong, Somalia
		case region(String)

		/// United Arab Emirates
		case area(String)

		/// Carribean Netherlands
		case islandName(String)

		/// China
		case prefectureLevelCity(String)

		/// Russia
		case subjectOfTheFederation(String)
		case county(String)

		/// Japan
		case prefecture(String)
		/// Japan
		case countySlashCity(String)
		/// Japan
		case furtherDivisionsLine0(String)

		/// Japan
		case furtherDivisionsLine1(String)

		/// Taiwan
		case townshipSlashDistrict(String)

		/// Colombia
		case department(String)

		/// UK
		case townSlashCity(String)

		/// Jordan
		case postalDistrict(String)

		/// Philippines
		case districtSlashSubdivision(String)
	}
}

extension PersonaData.PostalAddress.Field {
	public var valueAsString: String {
		switch self {
		case let .area(value):
			return value
		case let .countryOrRegion(value):
			return value.rawValue
		case let .streetLine0(value):
			return value
		case let .streetLine1(value):
			return value
		case let .postalCode(value):
			return value
		case let .postcode(value):
			return value
		case let .townSlashCity(value):
			return value
		case let .zip(value):
			return value
		case let .city(value):
			return value
		case let .state(value):
			return value
		case let .suburb(value):
			return value
		case let .neighbourhood(value):
			return value
		case let .province(value):
			return value
		case let .governorate(value):
			return value
		case let .district(value):
			return value
		case let .region(value):
			return value
		case let .prefectureLevelCity(value):
			return value
		case let .subjectOfTheFederation(value):
			return value
		case let .prefecture(value):
			return value
		case let .county(value):
			return value
		case let .countySlashCity(value):
			return value
		case let .islandName(value):
			return value
		case let .furtherDivisionsLine0(value):
			return value
		case let .furtherDivisionsLine1(value):
			return value
		case let .townshipSlashDistrict(value):
			return value
		case let .department(value):
			return value
		case let .postalDistrict(value):
			return value
		case let .districtSlashSubdivision(value):
			return value
		}
	}

	public var description: String {
		".\(discriminator.rawValue)(\(valueAsString))"
	}
}

extension PersonaData.PostalAddress.Field {
	private enum CodingKeys: String, CodingKey {
		case value, discriminator
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(Discriminator.self, forKey: .discriminator)
		switch discriminator {
		case .area:
			self = try .area(container.decode(String.self, forKey: .value))
		case .townSlashCity:
			self = try .townSlashCity(container.decode(String.self, forKey: .value))
		case .streetLine0:
			self = try .streetLine0(container.decode(String.self, forKey: .value))
		case .streetLine1:
			self = try .streetLine1(container.decode(String.self, forKey: .value))
		case .postalCode:
			self = try .postalCode(container.decode(String.self, forKey: .value))
		case .postalDistrict:
			self = try .postalDistrict(container.decode(String.self, forKey: .value))
		case .postcode:
			self = try .postcode(container.decode(String.self, forKey: .value))
		case .islandName:
			self = try .islandName(container.decode(String.self, forKey: .value))
		case .zip:
			self = try .zip(container.decode(String.self, forKey: .value))
		case .city:
			self = try .city(container.decode(String.self, forKey: .value))
		case .district:
			self = try .district(container.decode(String.self, forKey: .value))
		case .neighbourhood:
			self = try .neighbourhood(container.decode(String.self, forKey: .value))
		case .department:
			self = try .department(container.decode(String.self, forKey: .value))
		case .suburb:
			self = try .suburb(container.decode(String.self, forKey: .value))
		case .state:
			self = try .state(container.decode(String.self, forKey: .value))
		case .governorate:
			self = try .governorate(container.decode(String.self, forKey: .value))
		case .province:
			self = try .province(container.decode(String.self, forKey: .value))
		case .prefectureLevelCity:
			self = try .prefectureLevelCity(container.decode(String.self, forKey: .value))
		case .countryOrRegion:
			self = try .countryOrRegion(container.decode(PersonaData.PostalAddress.CountryOrRegion.self, forKey: .value))
		case .region:
			self = try .region(container.decode(String.self, forKey: .value))
		case .countySlashCity:
			self = try .countySlashCity(container.decode(String.self, forKey: .value))
		case .subjectOfTheFederation:
			self = try .subjectOfTheFederation(container.decode(String.self, forKey: .value))
		case .prefecture:
			self = try .prefecture(container.decode(String.self, forKey: .value))
		case .county:
			self = try .county(container.decode(String.self, forKey: .value))
		case .furtherDivisionsLine0:
			self = try .furtherDivisionsLine0(container.decode(String.self, forKey: .value))
		case .furtherDivisionsLine1:
			self = try .furtherDivisionsLine1(container.decode(String.self, forKey: .value))
		case .townshipSlashDistrict:
			self = try .townshipSlashDistrict(container.decode(String.self, forKey: .value))
		case .districtSlashSubdivision:
			self = try .districtSlashSubdivision(container.decode(String.self, forKey: .value))
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(discriminator, forKey: .discriminator)
		// YES we could use `valueAsString` computed property here and remove the switch... but maybe we wanna use different formatting...?
		switch self {
		case let .area(value):
			try container.encode(value, forKey: .value)
		case let .countryOrRegion(value):
			try container.encode(value, forKey: .value)
		case let .streetLine0(value):
			try container.encode(value, forKey: .value)
		case let .streetLine1(value):
			try container.encode(value, forKey: .value)
		case let .districtSlashSubdivision(value):
			try container.encode(value, forKey: .value)
		case let .postalCode(value):
			try container.encode(value, forKey: .value)
		case let .postcode(value):
			try container.encode(value, forKey: .value)
		case let .zip(value):
			try container.encode(value, forKey: .value)
		case let .city(value):
			try container.encode(value, forKey: .value)
		case let .state(value):
			try container.encode(value, forKey: .value)
		case let .islandName(value):
			try container.encode(value, forKey: .value)
		case let .suburb(value):
			try container.encode(value, forKey: .value)
		case let .neighbourhood(value):
			try container.encode(value, forKey: .value)
		case let .province(value):
			try container.encode(value, forKey: .value)
		case let .governorate(value):
			try container.encode(value, forKey: .value)
		case let .district(value):
			try container.encode(value, forKey: .value)
		case let .region(value):
			try container.encode(value, forKey: .value)
		case let .prefectureLevelCity(value):
			try container.encode(value, forKey: .value)
		case let .subjectOfTheFederation(value):
			try container.encode(value, forKey: .value)
		case let .prefecture(value):
			try container.encode(value, forKey: .value)
		case let .county(value):
			try container.encode(value, forKey: .value)
		case let .townSlashCity(value):
			try container.encode(value, forKey: .value)
		case let .countySlashCity(value):
			try container.encode(value, forKey: .value)
		case let .furtherDivisionsLine0(value):
			try container.encode(value, forKey: .value)
		case let .furtherDivisionsLine1(value):
			try container.encode(value, forKey: .value)
		case let .townshipSlashDistrict(value):
			try container.encode(value, forKey: .value)
		case let .department(value):
			try container.encode(value, forKey: .value)
		case let .postalDistrict(value):
			try container.encode(value, forKey: .value)
		}
	}
}

// MARK: - PersonaData.PostalAddress.Field.Discriminator
extension PersonaData.PostalAddress.Field {
	public enum Discriminator: String, Sendable, Hashable, Codable {
		case streetLine0
		case streetLine1
		case postalCode
		case postcode

		/// Jordan (String)
		case postalDistrict

		case zip
		case city
		case district
		case neighbourhood

		/// Carribean Netherlands
		case islandName

		/// Colombia
		case department

		case suburb
		case state
		case governorate
		case province
		case prefectureLevelCity
		case countryOrRegion
		case region
		case subjectOfTheFederation
		case area
		case prefecture

		// UK
		case townSlashCity

		case county
		case countySlashCity

		case furtherDivisionsLine0
		case furtherDivisionsLine1
		case townshipSlashDistrict

		/// Philippines
		case districtSlashSubdivision
	}
}

extension PersonaData.PostalAddress.Field {
	public var display: String {
		switch self {
		case .districtSlashSubdivision: return "District/Subdivision"
		case .countryOrRegion: return "Country or Region"
		case .streetLine0, .streetLine1: return "Street"
		case .postalCode: return "Postal code"
		case .postcode: return "Postcode"
		case .postalDistrict: return "Postal District"
		case .zip: return "ZIP"
		case .countySlashCity: return "County/City"
		case .prefectureLevelCity: return "Prefecture-level City"
		case .city: return "City"
		case .state: return "State"
		case .townSlashCity: return "Town/City"
		case .governorate: return "Governorate"
		case .district: return "District"
		case .neighbourhood: return "Neighbourhood"
		case .suburb: return "Suburb"
		case .province: return "Province"
		case .region: return "Region"
		case .area: return "Area"
		case .islandName: return "Carribean Netherlands"
		case .department: return "Department"
		case .subjectOfTheFederation: return "Subject of the Federation"
		case .prefecture: return "Prefecture"
		case .county: return "County"
		case .townshipSlashDistrict: return "Township/District"
		case .furtherDivisionsLine0, .furtherDivisionsLine1: return "Further Divisions"
		}
	}
}

// MARK: Discriminators
extension PersonaData.PostalAddress.Field {
	public var discriminator: Discriminator {
		switch self {
		case .countryOrRegion: return .countryOrRegion
		case .streetLine0: return .streetLine0
		case .streetLine1: return .streetLine1
		case .postalCode: return .postalCode
		case .postcode: return .postcode
		case .postalDistrict: return .postalDistrict
		case .zip: return .zip
		case .prefectureLevelCity: return .prefectureLevelCity
		case .city: return .city
		case .state: return .state
		case .district: return .district
		case .neighbourhood: return .neighbourhood
		case .suburb: return .suburb
		case .province: return .province
		case .townSlashCity: return .townSlashCity
		case .region: return .region
		case .area: return .area
		case .districtSlashSubdivision: return .districtSlashSubdivision
		case .subjectOfTheFederation: return .subjectOfTheFederation
		case .townshipSlashDistrict: return .townshipSlashDistrict
		case .islandName: return .islandName
		case .prefecture: return .prefecture
		case .county: return .county
		case .furtherDivisionsLine0: return .furtherDivisionsLine0
		case .furtherDivisionsLine1: return .furtherDivisionsLine1
		case .governorate: return .governorate
		case .department: return .department
		case .countySlashCity: return .countySlashCity
		}
	}
}
