import CasePaths
import Cryptography
import EngineToolkit
@testable import Profile
import RadixConnectModels
import SharedTestingModels
import SwiftUI
import TestingPrelude

// MARK: - DuplicateValuesFound
struct DuplicateValuesFound: Swift.Error {}

// MARK: - DuplicateIDOfValueFound
struct DuplicateIDOfValueFound: Swift.Error {}

// MARK: - PersonaFieldCollectionValueWithIDNotFound
struct PersonaFieldCollectionValueWithIDNotFound: Swift.Error {
	let id: UUID
}

// MARK: - Persona
public struct Persona: Sendable, Hashable, Codable {
	public let label: String
	public let personaData: PersonaData

	public struct PersonaData: Sendable, Hashable, Codable {
		public typealias Name = PersonaFieldOfKind<PersonaFieldValue.Name>

		public struct FieldCollectionOf<Value: Sendable & Hashable & Codable & BasePersonaFieldValueProtocol>: Sendable, Hashable, Codable {
			public private(set) var collection: IdentifiedArrayOf<PersonaFieldOfKind<Value>>
			public init(collection: IdentifiedArrayOf<PersonaFieldOfKind<Value>> = .init()) throws {
				guard Set(collection.map(\.value)).count == collection.count else {
					throw DuplicateValuesFound()
				}
				self.collection = collection
			}

			public mutating func add(_ field: PersonaFieldOfKind<Value>) throws {
				guard !contains(where: { $0.value == field.value }) else {
					throw DuplicateValuesFound()
				}
				let (wasInserted, _) = self.collection.append(field)
				guard wasInserted else {
					throw DuplicateIDOfValueFound()
				}
			}

			public mutating func update(_ updated: PersonaFieldOfKind<Value>) throws {
				guard contains(where: { $0.id == updated.id }) else {
					throw PersonaFieldCollectionValueWithIDNotFound(id: updated.id)
				}
				self.collection[id: updated.id] = updated
			}
		}

		public typealias EmailAddresses = FieldCollectionOf<PersonaFieldValue.EmailAddress>
		public typealias PostalAddresses = FieldCollectionOf<PersonaFieldValue.PostalAddress>

		public var name: Name?
		public var emailAddresses: EmailAddresses
		public var postalAddresses: PostalAddresses

		public init(
			name: Name? = nil,
			emailAddresses: EmailAddresses = [],
			postalAddresses: PostalAddresses = []
		) {
			self.name = name
			self.emailAddresses = emailAddresses
			self.postalAddresses = postalAddresses
		}
	}
}

// MARK: - Persona.PersonaData.FieldCollectionOf + RandomAccessCollection
extension Persona.PersonaData.FieldCollectionOf: RandomAccessCollection {
	public typealias Element = PersonaFieldOfKind<Value>

	public typealias Index = IdentifiedArrayOf<PersonaFieldOfKind<Value>>.Index

	public typealias SubSequence = IdentifiedArrayOf<PersonaFieldOfKind<Value>>.SubSequence

	public typealias Indices = IdentifiedArrayOf<PersonaFieldOfKind<Value>>.Indices

	public var startIndex: Index {
		collection.startIndex
	}

	public var indices: Indices {
		collection.indices
	}

	public var endIndex: Index {
		collection.endIndex
	}

	public func formIndex(after index: inout Index) {
		collection.formIndex(after: &index)
	}

	public func formIndex(before index: inout Index) {
		collection.formIndex(before: &index)
	}

	public subscript(bounds: Range<Index>) -> SubSequence {
		collection[bounds]
	}

	public subscript(position: Index) -> Element {
		collection[position]
	}
}

// MARK: - InitializableFromInputString
public protocol InitializableFromInputString: Sendable, Codable, Hashable {
	init?(_ input: String)
}

// MARK: - String + InitializableFromInputString
extension String: InitializableFromInputString {
	public init?(_ input: String) {
		self = input
	}
}

// MARK: - Int + InitializableFromInputString
extension Int: InitializableFromInputString {
	public init?(_ input: String) {
		guard let int = Self(input) else {
			return nil
		}
		self = int
	}
}

// MARK: - PersonaFieldValue.PostalAddress.Country + InitializableFromInputString
extension PersonaFieldValue.PostalAddress.Country: InitializableFromInputString {
	public init?(_ input: String) {
		guard let country = Self(rawValue: input) else {
			return nil
		}
		self = country
	}
}

extension Persona.PersonaData {
	public var all: OrderedSet<PersonaField> {
		.init(uncheckedUniqueElements: [
			name?.embed(),
		].compactMap { $0 })
	}
}

extension Persona {
	public var fields: OrderedSet<PersonaField> {
		personaData.all
	}
}

// MARK: - BasePersonaFieldValueProtocol
public protocol BasePersonaFieldValueProtocol {
	func embed() -> PersonaFieldValue
}

// MARK: - PersonaFieldValueProtocol
public protocol PersonaFieldValueProtocol: BasePersonaFieldValueProtocol {
	static var casePath: CasePath<PersonaFieldValue, Self> { get }
	static var kind: PersonaFieldKind { get }
}

public typealias PersonaField = PersonaFieldOfKind<PersonaFieldValue>

extension PersonaFieldOfKind {
	public func embed() -> PersonaField {
		.init(id: id, value: value.embed())
	}
}

// MARK: - PersonaFieldKind
public enum PersonaFieldKind: String, Sendable, Hashable, Codable {
	case name
	case emailAddress
	case postalAddress
}

// MARK: - PersonaFieldValue
public enum PersonaFieldValue: Sendable, Hashable, Codable, BasePersonaFieldValueProtocol {
	public var discriminator: PersonaFieldKind {
		switch self {
		case .name: return .name
		case .emailAddress: return .emailAddress
		case .postalAddress: return .postalAddress
		}
	}

	public func embed() -> PersonaFieldValue {
		switch self {
		case let .name(value): return value.embed()
		case let .emailAddress(value): return value.embed()
		case let .postalAddress(value): return value.embed()
		}
	}

	public struct Name: Sendable, Hashable, Codable, PersonaFieldValueProtocol {
		public static var casePath: CasePath<PersonaFieldValue, Self> = /PersonaFieldValue.name
		public static var kind = PersonaFieldKind.name

		/// First/Given/Fore-name, .e.g. `"John"`
		public let given: String

		/// Middle name, e.g. `"Fitzgerald"`
		public let middle: String?

		/// Last/Family/Sur-name, .e.g. `"Kennedey"`
		public let family: String

		public init(given: String, middle: String? = nil, family: String, variant: Variant) {
			self.given = given
			self.middle = middle
			self.family = family
			self.variant = variant
		}

		public enum Variant: String, Sendable, Hashable, Codable {
			/// order: `given middle family`
			case western

			/// order: `family (middle) given`
			case eastern
		}

		public let variant: Variant
	}

	public struct EmailAddress: Sendable, Hashable, Codable, PersonaFieldValueProtocol {
		public static var casePath: CasePath<PersonaFieldValue, Self> = /PersonaFieldValue.emailAddress
		public static var kind = PersonaFieldKind.emailAddress

		public let email: String

		public init(validating email: String) throws {
			guard email.isEmailAddress else {
				throw InvalidEmailAddress(invalid: email)
			}
			self.email = email
		}

		struct InvalidEmailAddress: Swift.Error {
			let invalid: String
		}
	}

	public struct PostalAddress: Sendable, Hashable, Codable, PersonaFieldValueProtocol {
		public static var casePath: CasePath<PersonaFieldValue, Self> = /PersonaFieldValue.postalAddress
		public static var kind = PersonaFieldKind.postalAddress

		public enum Field: Sendable, Hashable, Codable {
			public enum Discriminator: String, Sendable, Hashable, Codable {
				case streetLine0
				case streetLine1
				case postalCodeString
				case postalCodeNumber
				case postcodeNumber

				/// UK
				case postcodeString

				case zipNumber
				case city
				case district
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
					case .streetLine0: return "Street"
					case .streetLine1: return "Street"
					case .postalCodeString: return "Postal code"
					case .postalCodeNumber: return "Postal code"
					case .postcodeString: return "Postcode"
					case .postcodeNumber: return "Postcode"
					case .zipNumber: return "ZIP"
					case .prefectureLevelCity: return "Prefecture-level City"
					case .city: return "City"
					case .state: return "State"
					case .governorate: return "Governorate"
					case .district: return "District"
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
					case .furtherDivisionsLine0: return "Further Divisions"
					case .furtherDivisionsLine1: return "Further Divisions"
					}
				}
			}

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
			case district(String)

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

			public var keyboardType: UIKeyboardType {
				switch self {
				case .zipNumber, .postalCodeNumber, .postcodeNumber: return .numbersAndPunctuation
				default: return .default
				}
			}

			public var valueType: any InitializableFromInputString.Type {
				switch self {
				case .zipNumber, .postalCodeNumber, .postcodeNumber: return Int.self
				case .country: return Country.self
				default: return String.self
				}
			}

			public var discriminator: Discriminator {
				switch self {
				case .country: return .country
				case .streetLine0: return .streetLine0
				case .streetLine1: return .streetLine1
				case .postalCodeString: return .postalCodeString
				case .postalCodeNumber: return .postalCodeNumber
				case .postcodeNumber: return .postcodeNumber
				case .postcodeString: return .postcodeString
				case .zipNumber: return .zipNumber

				case .prefectureLevelCity: return .prefectureLevelCity

				case .city: return .city
				case .state: return .state
				case .district: return .district
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

		/// The research house found that the top destination for crypto adoption is (in order):
		/// Australia,
		/// US
		/// Brazil,
		/// United Arab Emirates (UAE),
		/// Hong Kong
		/// Taiwan
		/// India,
		/// Canada
		/// Turkey
		/// Singapore
		public enum Country: String, Sendable, Hashable, Codable {
			case afghanistan
			case argentina
			case angola
			case algeria
			case albania
			case andorra
			case armenia
			case australia
			case austria
			case bangladesh
			case azerbaijan
			case belarus
			case belgium
			case bosniaAndHerzegovinia
			case bulgaria
			case brazil
			case canada
			case cameroon
			case china
			case colombia
			case croatia
			case cyprus
			case czechRepublic
			case democraticRepublicOfTheCongo
			case denmark
			case egypt
			case estonia
			case ethiopia
			case finland
			case france
			case georgia
			case germany
			case ghana
			case greece
			case hongKong
			case hungary
			case iceland
			case india
			case iran
			case iraq
			case ireland
			case italy
			case ivoryCoast; public static let côteDIvoire: Self = .ivoryCoast
			case indonesia
			case japan
			case kazakhstan
			case kenya
			case latvia
			case liechtenstein
			case lithuania
			case luxembourg
			case madagascar
			case malaysia
			case malta
			case mexico
			case moldova
			case monaco
			case mozambique
			case montenegro
			case morocco
			case myanmar
			case nepal
			case netherlands
			case niger
			case northKorea
			case northMacedonia
			case norway
			case nigeria
			case pakistan
			case philippines
			case poland
			case peru
			case romania
			case russia
			case saudiArabia
			case sanMarino
			case serbia
			case singapore
			case slovakia
			case slovenia
			case southKorea
			case southAfrica
			case spain
			case sudan
			case sweden
			case switzerland
			case taiwan
			case tanzania
			case thailand
			case turkey
			case vietnam
			case uganda
			case ukraine
			case unitedArabEmirates
			case unitedKingdom
			case unitedStates
			case uzbekistan
			case vaticanCity
			case venzuela
			case yemen

			var fields: [[PostalAddress.Field.Discriminator]] {
				switch self {
				case .afghanistan:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.country],
					]
				case .argentina:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.province],
						[.country],
					]
				case .angola:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.country],
					]
				case .algeria:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .australia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.suburb],
						[.state, .postalCodeNumber],
						[.country],
					]

				case .bangladesh:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city, .postalCodeNumber],
						[.country],
					]

				case .brazil:
					return [
						[.streetLine0],
						[.streetLine1],
						[.neighbourhood],
						[.city],
						[.state],
						[.postalCodeNumber],
						[.country],
					]

				case .cameroon:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.country],
					]
				case .canada:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.province, .postalCodeString],
						[.country],
					]

				case .china:
					return [
						[.country],
						[.province],
						[.prefectureLevelCity],
						[.district],
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber],
					]

				case .colombia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city, .postalCodeNumber],
						[.department],
						[.country],
					]

				case .democraticRepublicOfTheCongo:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city, .postalCodeNumber],
						[.country],
					]

				case .ethiopia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]

				case .egypt:
					return [
						[.streetLine0],
						[.streetLine1],
						[.district],
						[.governorate],
						[.country],
					]

				case .france:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]

				case .germany:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]

				case .ghana:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.country],
					]

				case .hongKong:
					return [
						[.country],
						[.region, .district],
						[.streetLine0],
						[.streetLine1],
					]

				case .india:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city, .postcodeNumber],
						[.state],
						[.country],
					]

				case .iran:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]

				case .iraq:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.postalCodeNumber],
						[.country],
					]

				case .italy:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.province, .country],
					]

				case .ivoryCoast:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]

				case .kenya:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.postalCodeNumber],
						[.country],
					]

				case .japan:
					return [
						[.postalCodeNumber],
						[.prefecture, .county],
						[.furtherDivisionsLine0],
						[.furtherDivisionsLine1],
						[.country],
					]

				case .indonesia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.province, .postalCodeNumber],
						[.country],
					]

				case .madagascar:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .malaysia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.state],
						[.country],
					]

				case .mexico:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.state],
						[.country],
					]

				case .morocco:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]

				case .mozambique:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.province],
						[.country],
					]

				case .myanmar:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city, .postalCodeNumber],
						[.country],
					]

				case .nepal:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city, .postalCodeNumber],
						[.country],
					]

				case .niger:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]

				case .nigeria:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city, .postalCodeNumber],
						[.state],
						[.country],
					]

				case .northKorea:
					return [
						[.country],
						[.province],
						[.city],
						[.streetLine0],
						[.streetLine1],
					]

				case .pakistan:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city, .postalCodeNumber],
						[.country],
					]

				case .philippines:
					return [
						[.streetLine0],
						[.streetLine1],
						[.district, .postalCodeNumber],
						[.city, .country],
					]

				case .peru:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city, .postalCodeNumber],
						[.country],
					]

				case .poland:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]

				case .russia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.subjectOfTheFederation],
						[.country],
						[.postalCodeNumber],
					]

				case .saudiArabia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.district],
						[.city, .postalCodeNumber],
						[.country],
					]

				case .singapore:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city, .postalCodeNumber],
						[.country],
					]

				case .spain:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.province, .country],
					]

				case .southAfrica:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.province],
						[.postalCodeNumber],
						[.country],
					]

				case .southKorea:
					return [
						[.country],
						[.province],
						[.city],
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber],
					]

				case .sweden:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]

				case .sudan:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber],
						[.city],
						[.country],
					]

				case .taiwan:
					return [
						[.country],
						[.zipNumber, .county],
						[.township],
						[.streetLine0],
						[.streetLine1],
					]

				case .tanzania:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.country],
					]

				case .thailand:
					return [
						[.streetLine0],
						[.streetLine1],
						[.district],
						[.province, .postalCodeNumber],
						[.country],
					]

				case .turkey:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .district],
						[.city, .country],
					]

				case .uganda:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.country],
					]
				case .ukraine:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.province],
						[.postalCodeNumber],
						[.country],
					]

				case .unitedStates:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.state, .zipNumber],
						[.country],
					]

				case .unitedArabEmirates:
					return [
						[.streetLine0],
						[.streetLine1],
						[.area],
						[.city],
						[.country],
					]

				case .unitedKingdom:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.county],
						[.postcodeString],
						[.country],
					]

				case .uzbekistan:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.country],
						[.postalCodeNumber],
					]

				case .venzuela:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city, .postalCodeNumber],
						[.state],
						[.country],
					]
				case .vietnam:
					return [
						[.streetLine0],
						[.streetLine1],
						[.province],
						[.city, .postalCodeNumber],
						[.country],
					]

				case .yemen:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .albania:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.country],
					]
				case .andorra:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .armenia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .austria:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .azerbaijan:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .belarus:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.province],
						[.country],
					]
				case .belgium:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .bosniaAndHerzegovinia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .bulgaria:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .croatia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .cyprus:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .czechRepublic:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .denmark:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .estonia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .finland:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .georgia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .greece:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .hungary:
					return [
						[.postalCodeNumber, .city],
						[.streetLine0],
						[.streetLine1],
						[.country],
					]
				case .iceland:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .ireland:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.county, .postcodeNumber],
						[.country],
					]
				case .kazakhstan:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.district],
						[.region],
						[.country],
						[.postalCodeNumber],
					]
				case .latvia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city, .postalCodeNumber],
						[.country],
					]
				case .liechtenstein:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .lithuania:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .luxembourg:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .malta:
					return [
						[.streetLine0],
						[.streetLine1],
						[.city],
						[.postalCodeNumber],
						[.country],
					]
				case .moldova:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .monaco:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .montenegro:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .netherlands:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .northMacedonia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .norway:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .romania:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .sanMarino:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.province],
						[.country],
					]
				case .serbia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .slovakia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .slovenia:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .switzerland:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				case .vaticanCity:
					return [
						[.streetLine0],
						[.streetLine1],
						[.postalCodeNumber, .city],
						[.country],
					]
				}
			}
		}

		public let country: Country
	}

	case name(Name)
	case emailAddress(EmailAddress)
	case postalAddress(PostalAddress)
}

// MARK: - PersonaFieldOfKind
/// * Names
/// * Postal Addresses
/// * Email Addresses
/// * URL Addresses
/// * Telephone numbers
/// * Birthday
public struct PersonaFieldOfKind<Value>: Sendable, Hashable, Codable, Identifiable where Value: Sendable & Hashable & Codable & BasePersonaFieldValueProtocol {
	public let id: UUID
	public var value: Value

	public init(
		id: UUID? = nil,
		value: Value
	) {
		@Dependency(\.uuid) var uuid
		self.id = id ?? uuid()
		self.value = value
	}
}

extension PersonaFieldValueProtocol {
	public var kind: PersonaFieldKind { Self.kind }
	public var casePath: CasePath<PersonaFieldValue, Self> { Self.casePath }

	public func embed() -> PersonaFieldValue {
		casePath.embed(self)
	}

	public static func extract(from fieldValue: PersonaFieldValue) -> Self? {
		casePath.extract(from: fieldValue)
	}
}

extension PersonaFieldValue {
	public func extract<F>(_ type: F.Type = F.self) -> F? where F: PersonaFieldValueProtocol {
		F.extract(from: self)
	}

	public func extract<F>(as _: F.Type = F.self) throws -> F where F: PersonaFieldValueProtocol {
		guard let extracted = extract(F.self) else {
			throw IncorrectPersonaFieldType(expectedKind: F.kind, actualKind: discriminator)
		}
		return extracted
	}
}

// MARK: - IncorrectPersonaFieldType
public struct IncorrectPersonaFieldType: Swift.Error {
	public let expectedKind: PersonaFieldKind
	public let actualKind: PersonaFieldKind
}

extension PersonaFieldValue.Name {
	public var valueForDapp: String {
		let components: [String?] = {
			switch variant {
			case .western: return [given, middle, family]
			case .eastern: return [family, middle, given]
			}
		}()
		return components.compactMap { $0 }.joined(separator: " ")
	}
}

// MARK: - PersonaFieldValue.EmailAddress + ExpressibleByStringLiteral
extension PersonaFieldValue.EmailAddress: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		try! self.init(validating: value)
	}
}

// MARK: - Persona.PersonaData.FieldCollectionOf + ExpressibleByArrayLiteral
extension Persona.PersonaData.FieldCollectionOf: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: PersonaFieldOfKind<Value>...) {
		try! self.init(collection: .init(uncheckedUniqueElements: elements))
	}
}

// MARK: - PersonaFieldTests
final class PersonaFieldTests: TestCase {
	func test_name_western() throws {
		let persona = withDependencies {
			$0.uuid = .incrementing
		} operation: {
			Persona(
				label: "Mr President",
				personaData: .init(
					name: .init(
						value: .init(
							given: "John",
							middle: "Fitzgerald",
							family: "Kennedy",
							variant: .western
						)
					)
				)
			)
		}

		let aName = try dappRequest(value: \.name, from: persona)
		XCTAssertEqual(aName.value.valueForDapp, "John Fitzgerald Kennedy")
	}

	func test_name_eastern() throws {
		let persona = withDependencies {
			$0.uuid = .incrementing
		} operation: {
			Persona(
				label: "Best Director",
				personaData: .init(
					name: .init(
						value: .init(
							given: "Chan-wook",
							family: "Park",
							variant: .eastern
						)
					)
				)
			)
		}
		let aName = try dappRequest(value: \.name, from: persona)
		XCTAssertEqual(aName.value.valueForDapp, "Park Chan-wook")
	}

	func test_email_addresses() throws {
		let persona = withDependencies {
			$0.uuid = .incrementing
		} operation: {
			Persona(
				label: "Dr Email",
				personaData: .init(
					emailAddresses: [
						.init(value: "hi@rdx.works"),
						.init(value: "bye@rdx.works"),
					]
				)
			)
		}

		let emails = try dappRequest(values: \.emailAddresses, from: persona)
		XCTAssertEqual(emails.map(\.value), ["hi@rdx.works", "bye@rdx.works"])
	}

	func test_assert_personaData_fieldCollectionOf_cannot_contain_duplicated_values() {
		XCTAssertThrowsError(
			try Persona.PersonaData.EmailAddresses(
				collection: [
					.init(id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"), value: "hi@rdx.works"),
					.init(id: .init(uuidString: "AAAAAAAA-9999-8888-7777-AAAAAAAAAAAA"), value: "hi@rdx.works"), // same value cannot be used twice, even though UUID differs!
				]
			)
		)
	}

	func test_assert_personaData_fieldCollectionOf_cannot_add_duplicate_value() throws {
		var fieldCollection = try Persona.PersonaData.EmailAddresses(
			collection: [
				.init(id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"), value: "hi@rdx.works"),
			]
		)
		XCTAssertThrowsError(
			try fieldCollection.add(
				.init(id: .init(uuidString: "AAAAAAAA-9999-8888-7777-AAAAAAAAAAAA"), value: "hi@rdx.works")
			)
		)
	}

	func test_assert_personaData_fieldCollectionOf_cannot_add_duplicate_id() throws {
		var fieldCollection = try Persona.PersonaData.EmailAddresses(
			collection: [
				.init(id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"), value: "hi@rdx.works"),
			]
		)
		XCTAssertThrowsError(
			try fieldCollection.add(
				.init(id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"), value: "bye@rdx.works")
			)
		)
	}

	func test_assert_personaData_fieldCollectionOf_can_add_another_value() throws {
		var fieldCollection = try Persona.PersonaData.EmailAddresses(
			collection: [
				.init(id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"), value: "hi@rdx.works"),
			]
		)
		try fieldCollection.add(
			.init(id: .init(uuidString: "AAAAAAAA-9999-8888-7777-AAAAAAAAAAAA"), value: "bye@rdx.works")
		)
		XCTAssertEqual(fieldCollection.map(\.value), ["hi@rdx.works", "bye@rdx.works"])
	}

	func test_update_emails() throws {
		var email = Persona.PersonaData.EmailAddresses.Element(
			id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"),
			value: "hi@rdx.works"
		)
		var fieldCollection = try Persona.PersonaData.EmailAddresses(
			collection: [
				email,
			]
		)
		email.value = "bye@rdx.works"
		XCTAssertNoThrow(try fieldCollection.update(email))
		XCTAssertEqual(fieldCollection[0].value, "bye@rdx.works")
	}

	func test_assert_update_unknown_id_throws() throws {
		var fieldCollection = try Persona.PersonaData.EmailAddresses(
			collection: [
				.init(id: .init(uuidString: "AAAAAAAA-9999-8888-7777-AAAAAAAAAAAA"), value: "hi@rdx.works"),
			]
		)
		XCTAssertThrowsError(try fieldCollection.update(.init(
			id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"),
			value: "bye@rdx.works"
		)))
	}

	func dappRequest<Kind: PersonaFieldValueProtocol>(
		values keyPath: KeyPath<Persona.PersonaData, Persona.PersonaData.FieldCollectionOf<Kind>>,
		from persona: Persona
	) throws -> Persona.PersonaData.FieldCollectionOf<Kind> {
		persona.personaData[keyPath: keyPath]
	}

	func dappRequest<Kind: PersonaFieldValueProtocol>(
		value keyPath: KeyPath<Persona.PersonaData, PersonaFieldOfKind<Kind>?>,
		from persona: Persona
	) throws -> PersonaFieldOfKind<Kind> {
		guard let field = persona.personaData[keyPath: keyPath] else {
			throw NoSuchField()
		}
		return field
	}
}

// MARK: - NoSuchField
struct NoSuchField: Error {}
