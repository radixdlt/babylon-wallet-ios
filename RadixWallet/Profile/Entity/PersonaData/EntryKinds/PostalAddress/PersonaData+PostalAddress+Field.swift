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
			value
		case let .countryOrRegion(value):
			value.rawValue
		case let .streetLine0(value):
			value
		case let .streetLine1(value):
			value
		case let .postalCode(value):
			value
		case let .postcode(value):
			value
		case let .townSlashCity(value):
			value
		case let .zip(value):
			value
		case let .city(value):
			value
		case let .state(value):
			value
		case let .suburb(value):
			value
		case let .neighbourhood(value):
			value
		case let .province(value):
			value
		case let .governorate(value):
			value
		case let .district(value):
			value
		case let .region(value):
			value
		case let .prefectureLevelCity(value):
			value
		case let .subjectOfTheFederation(value):
			value
		case let .prefecture(value):
			value
		case let .county(value):
			value
		case let .countySlashCity(value):
			value
		case let .islandName(value):
			value
		case let .furtherDivisionsLine0(value):
			value
		case let .furtherDivisionsLine1(value):
			value
		case let .townshipSlashDistrict(value):
			value
		case let .department(value):
			value
		case let .postalDistrict(value):
			value
		case let .districtSlashSubdivision(value):
			value
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
		case .districtSlashSubdivision: "District/Subdivision"
		case .countryOrRegion: "Country or Region"
		case .streetLine0, .streetLine1: "Street"
		case .postalCode: "Postal code"
		case .postcode: "Postcode"
		case .postalDistrict: "Postal District"
		case .zip: "ZIP"
		case .countySlashCity: "County/City"
		case .prefectureLevelCity: "Prefecture-level City"
		case .city: "City"
		case .state: "State"
		case .townSlashCity: "Town/City"
		case .governorate: "Governorate"
		case .district: "District"
		case .neighbourhood: "Neighbourhood"
		case .suburb: "Suburb"
		case .province: "Province"
		case .region: "Region"
		case .area: "Area"
		case .islandName: "Carribean Netherlands"
		case .department: "Department"
		case .subjectOfTheFederation: "Subject of the Federation"
		case .prefecture: "Prefecture"
		case .county: "County"
		case .townshipSlashDistrict: "Township/District"
		case .furtherDivisionsLine0, .furtherDivisionsLine1: "Further Divisions"
		}
	}
}

// MARK: Discriminators
extension PersonaData.PostalAddress.Field {
	public var discriminator: Discriminator {
		switch self {
		case .countryOrRegion: .countryOrRegion
		case .streetLine0: .streetLine0
		case .streetLine1: .streetLine1
		case .postalCode: .postalCode
		case .postcode: .postcode
		case .postalDistrict: .postalDistrict
		case .zip: .zip
		case .prefectureLevelCity: .prefectureLevelCity
		case .city: .city
		case .state: .state
		case .district: .district
		case .neighbourhood: .neighbourhood
		case .suburb: .suburb
		case .province: .province
		case .townSlashCity: .townSlashCity
		case .region: .region
		case .area: .area
		case .districtSlashSubdivision: .districtSlashSubdivision
		case .subjectOfTheFederation: .subjectOfTheFederation
		case .townshipSlashDistrict: .townshipSlashDistrict
		case .islandName: .islandName
		case .prefecture: .prefecture
		case .county: .county
		case .furtherDivisionsLine0: .furtherDivisionsLine0
		case .furtherDivisionsLine1: .furtherDivisionsLine1
		case .governorate: .governorate
		case .department: .department
		case .countySlashCity: .countySlashCity
		}
	}
}
