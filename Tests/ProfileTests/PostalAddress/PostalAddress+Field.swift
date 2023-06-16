import Foundation

// MARK: - PersonaFieldValue.PostalAddress.Field
extension PersonaFieldValue.PostalAddress {
	public enum Field: Sendable, Hashable, Codable {
		case country(Country)
		case streetLine0(String)
		case streetLine1(String)

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
		case governorate

		/// Hong Kong
		case districtString(String)

		/// Macao
		case districtNumber(Int)

		/// Hong Kong
		case region(String)

		/// United Arab Emirates
		case area(String)

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

// MARK: - PersonaFieldValue.PostalAddress.Field.Discriminator
extension PersonaFieldValue.PostalAddress.Field {
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

		/// Colombia
		case department

		case suburb
		case state
		case governorate
		case province
		case prefectureLevelCity
		case country
		case region
		case subjectOfTheFederation
		case area
		case prefecture
		case county
		case furtherDivisionsLine0
		case furtherDivisionsLine1
		case township

		public var display: String {
			switch self {
			case .country: return "Country"
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
extension PersonaFieldValue.PostalAddress.Field {
	public var discriminator: Discriminator {
		switch self {
		case .country: return .country
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
extension PersonaFieldValue.PostalAddress.Field {
	#if canImport(UIKit)
	public var keyboardType: UIKeyboardType {
		switch self {
		case .zipNumber, .postalCodeNumber, .postcodeNumber, .districtNumber: return .numbersAndPunctuation
		default: return .default
		}
	}
	#endif // canImport(UIKit)
}

extension PersonaFieldValue.PostalAddress.Field {
	public var valueType: any InitializableFromInputString.Type {
		switch self {
		case .zipNumber, .postalCodeNumber, .postcodeNumber, .districtNumber: return Int.self
		case .country: return PersonaFieldValue.PostalAddress.Country.self
		default: return String.self
		}
	}
}
