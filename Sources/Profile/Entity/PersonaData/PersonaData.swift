import Prelude

// MARK: - PersonaData
public struct PersonaData: Sendable, Hashable, Codable {
	public typealias Name = PersonaDataEntryOfKind<PersonaDataEntry.Name>
	public typealias DateOfBirth = PersonaDataEntryOfKind<PersonaDataEntry.DateOfBirth>

	public typealias EmailAddresses = EntryCollectionOf<PersonaDataEntry.EmailAddress>
	public typealias PostalAddresses = EntryCollectionOf<PersonaDataEntry.PostalAddress>
	public typealias PhoneNumbers = EntryCollectionOf<PersonaDataEntry.PhoneNumber>

	public var name: Name?
	public var dateOfBirth: DateOfBirth?
	public var emailAddresses: EmailAddresses
	public var postalAddresses: PostalAddresses
	public var phoneNumbers: PhoneNumbers

	public var entries: [PersonaDataEntryOfKind<PersonaDataEntry>] {
		var sequence: [PersonaDataEntryOfKind<PersonaDataEntry>?] = []
		sequence.append(name?.embed())
		sequence.append(dateOfBirth?.embed())
		sequence.append(contentsOf: emailAddresses.map { $0.embed() })
		sequence.append(contentsOf: postalAddresses.map { $0.embed() })
		sequence.append(contentsOf: phoneNumbers.map { $0.embed() })
		return sequence.compactMap { $0 }
	}

	public init(
		name: Name? = nil,
		dateOfBirth: DateOfBirth? = nil,
		emailAddresses: EmailAddresses = .init(),
		postalAddresses: PostalAddresses = .init(),
		phoneNumbers: PhoneNumbers = .init()
	) {
		self.name = name
		self.dateOfBirth = dateOfBirth
		self.emailAddresses = emailAddresses
		self.postalAddresses = postalAddresses
		self.phoneNumbers = phoneNumbers
	}
}

// MARK: PersonaData.EntryCollectionOf
extension PersonaData {
	public struct EntryCollectionOf<Value: Sendable & Hashable & Codable & BasePersonaFieldValueProtocol>: Sendable, Hashable, Codable {
		public private(set) var collection: IdentifiedArrayOf<PersonaDataEntryOfKind<Value>>

		public init() {
			self.collection = []
		}

		public init(collection: IdentifiedArrayOf<PersonaDataEntryOfKind<Value>> = .init()) throws {
			guard Set(collection.map(\.value)).count == collection.count else {
				throw DuplicateValuesFound()
			}
			self.collection = collection
		}

		public mutating func add(_ field: PersonaDataEntryOfKind<Value>) throws {
			guard !contains(where: { $0.value == field.value }) else {
				throw DuplicateValuesFound()
			}
			let (wasInserted, _) = self.collection.append(field)
			guard wasInserted else {
				throw DuplicateIDOfValueFound()
			}
		}

		public mutating func update(_ updated: PersonaDataEntryOfKind<Value>) throws {
			guard contains(where: { $0.id == updated.id }) else {
				throw PersonaFieldCollectionValueWithIDNotFound(id: updated.id)
			}
			self.collection[id: updated.id] = updated
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(collection.elements)
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			try self.init(
				collection: container.decode(IdentifiedArrayOf<PersonaDataEntryOfKind<Value>>.self)
			)
		}
	}
}

// MARK: - PersonaData.EntryCollectionOf + RandomAccessCollection
extension PersonaData.EntryCollectionOf: RandomAccessCollection {
	public typealias Element = PersonaDataEntryOfKind<Value>

	public typealias Index = IdentifiedArrayOf<PersonaDataEntryOfKind<Value>>.Index

	public typealias SubSequence = IdentifiedArrayOf<PersonaDataEntryOfKind<Value>>.SubSequence

	public typealias Indices = IdentifiedArrayOf<PersonaDataEntryOfKind<Value>>.Indices

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
