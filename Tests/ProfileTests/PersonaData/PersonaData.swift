import Prelude

// MARK: - Persona.PersonaData
extension Persona {
	public struct PersonaData: Sendable, Hashable, Codable {
		public typealias Name = PersonaDataEntryOfKind<PersonaDataEntry.Name>
		public typealias DateOfBirth = PersonaDataEntryOfKind<PersonaDataEntry.DateOfBirth>

		public typealias EmailAddresses = EntryCollectionOf<PersonaDataEntry.EmailAddress>
		public typealias PostalAddresses = EntryCollectionOf<PersonaDataEntry.PostalAddress>

		public var name: Name?
		public var dateOfBirth: DateOfBirth?
		public var emailAddresses: EmailAddresses
		public var postalAddresses: PostalAddresses

		public init(
			name: Name? = nil,
			dateOfBirth: DateOfBirth? = nil,
			emailAddresses: EmailAddresses = [],
			postalAddresses: PostalAddresses = []
		) {
			self.name = name
			self.dateOfBirth = dateOfBirth
			self.emailAddresses = emailAddresses
			self.postalAddresses = postalAddresses
		}
	}
}

// MARK: - Persona.PersonaData.EntryCollectionOf
extension Persona.PersonaData {
	public struct EntryCollectionOf<Value: Sendable & Hashable & Codable & BasePersonaFieldValueProtocol>: Sendable, Hashable, Codable {
		public private(set) var collection: IdentifiedArrayOf<PersonaDataEntryOfKind<Value>>
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
			var container = try decoder.singleValueContainer()
			try self.init(
				collection: container.decode(IdentifiedArrayOf<PersonaDataEntryOfKind<Value>>.self)
			)
		}
	}
}

// MARK: - Persona.PersonaData.EntryCollectionOf + RandomAccessCollection
extension Persona.PersonaData.EntryCollectionOf: RandomAccessCollection {
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
