import Foundation

// MARK: - PersonaData.PostalAddress.Field
extension PersonaData.PostalAddress {
	public enum Field: Sendable, Hashable, Codable, Identifiable {
		public typealias ID = Discriminator
		public var id: ID {
			discriminator
		}

		case countryOrRegion(CountryOrRegion)
		case streetLine0(String)
		case streetLine1(String = "")

		case postalCodeString(String)

		/// Sweden
		case postalCodeNumber(Int)

		/// "Postcode" e.g.: `India`
		case postcodeNumber(Int)

		/// "Postcode" .e.g. UK
		case postcodeString(String)

		/// US
		case zipNumber(Int)

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
		case districtString(String)

		/// Macao
		case districtNumber(Int)

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

		/// Japan
		case prefecture(String)
		/// Japan
		case county(String)
		/// Japan
		case furtherDivisionsLine0(String)

		/// Japan
		case furtherDivisionsLine1(String)

		/// Taiwan
		case township(String)

		/// Colombia
		case department(String)

		/// Jordan
		case postalDistrict(String)
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
		case let .postalCodeString(value):
			return value
		case let .postalCodeNumber(value):
			return value.description
		case let .postcodeNumber(value):
			return value.description
		case let .postcodeString(value):
			return value
		case let .zipNumber(value):
			return value.description
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
		case let .districtString(value):
			return value
		case let .districtNumber(value):
			return value.description
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
		case let .islandName(value):
			return value
		case let .furtherDivisionsLine0(value):
			return value
		case let .furtherDivisionsLine1(value):
			return value
		case let .township(value):
			return value
		case let .department(value):
			return value
		case let .postalDistrict(value):
			return value
		}
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
		case .streetLine0:
			self = try .streetLine0(container.decode(String.self, forKey: .value))
		case .streetLine1:
			self = try .streetLine1(container.decode(String.self, forKey: .value))
		case .postalCodeString:
			self = try .postalCodeString(container.decode(String.self, forKey: .value))
		case .postalCodeNumber:
			self = try .postalCodeNumber(container.decode(Int.self, forKey: .value))
		case .postcodeNumber:
			self = try .postcodeNumber(container.decode(Int.self, forKey: .value))
		case .postalDistrict:
			self = try .postalDistrict(container.decode(String.self, forKey: .value))
		case .postcodeString:
			self = try .postcodeString(container.decode(String.self, forKey: .value))
		case .islandName:
			self = try .islandName(container.decode(String.self, forKey: .value))
		case .zipNumber:
			self = try .zipNumber(container.decode(Int.self, forKey: .value))
		case .city:
			self = try .city(container.decode(String.self, forKey: .value))
		case .districtNumber:
			self = try .districtNumber(container.decode(Int.self, forKey: .value))
		case .districtString:
			self = try .districtString(container.decode(String.self, forKey: .value))
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
		case .township:
			self = try .township(container.decode(String.self, forKey: .value))
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
		case let .postalCodeString(value):
			try container.encode(value, forKey: .value)
		case let .postalCodeNumber(value):
			try container.encode(value, forKey: .value)
		case let .postcodeNumber(value):
			try container.encode(value, forKey: .value)
		case let .postcodeString(value):
			try container.encode(value, forKey: .value)
		case let .zipNumber(value):
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
		case let .districtString(value):
			try container.encode(value, forKey: .value)
		case let .districtNumber(value):
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
		case let .furtherDivisionsLine0(value):
			try container.encode(value, forKey: .value)
		case let .furtherDivisionsLine1(value):
			try container.encode(value, forKey: .value)
		case let .township(value):
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
		case postalCodeString
		case postalCodeNumber
		case postcodeNumber

		/// Jordan (String)
		case postalDistrict

		/// UK
		case postcodeString

		case zipNumber
		case city
		case districtNumber
		case districtString
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
		case county
		case furtherDivisionsLine0
		case furtherDivisionsLine1
		case township

		// FIXME: Strings localize this
		public var display: String {
			switch self {
			case .countryOrRegion: return "Country"
			case .streetLine0, .streetLine1: return "Street"
			case .postalCodeString, .postalCodeNumber: return "Postal code"
			case .postcodeString, .postcodeNumber: return "Postcode"
			case .postalDistrict: return "Postal District"
			case .zipNumber: return "ZIP"
			case .prefectureLevelCity: return "Prefecture-level City"
			case .city: return "City"
			case .state: return "State"
			case .governorate: return "Governorate"
			case .districtString, .districtNumber: return "District"
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
			case .township: return "Township"
			case .furtherDivisionsLine0, .furtherDivisionsLine1: return "Further Divisions"
			}
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
		case .postalCodeString: return .postalCodeString
		case .postalCodeNumber: return .postalCodeNumber
		case .postcodeNumber: return .postcodeNumber
		case .postcodeString: return .postcodeString
		case .postalDistrict: return .postalDistrict
		case .zipNumber: return .zipNumber

		case .prefectureLevelCity: return .prefectureLevelCity

		case .city: return .city
		case .state: return .state
		case .districtNumber: return .districtNumber
		case .districtString: return .districtString
		case .neighbourhood: return .neighbourhood
		case .suburb: return .suburb
		case .province: return .province
		case .region: return .region
		case .area: return .area
		case .subjectOfTheFederation: return .subjectOfTheFederation
		case .township: return .township
		case .islandName: return .islandName

		case .prefecture: return .prefecture
		case .county: return .county
		case .furtherDivisionsLine0: return .furtherDivisionsLine0
		case .furtherDivisionsLine1: return .furtherDivisionsLine1
		case .governorate: return .governorate
		case .department: return .department
		}
	}
}

#if canImport(UIKit)
import UIKit
#endif // canImport(UIKit)
extension PersonaData.PostalAddress.Field {
	#if canImport(UIKit)
	public var keyboardType: UIKeyboardType {
		switch self {
		case .zipNumber, .postalCodeNumber, .postcodeNumber, .districtNumber: return .numbersAndPunctuation
		default: return .default
		}
	}
	#endif // canImport(UIKit)
}

extension PersonaData.PostalAddress.Field {
	public var valueType: any InitializableFromInputString.Type {
		switch self {
		case .zipNumber, .postalCodeNumber, .postcodeNumber, .districtNumber: return Int.self
		case .countryOrRegion: return PersonaData.PostalAddress.CountryOrRegion.self
		default: return String.self
		}
	}
}
