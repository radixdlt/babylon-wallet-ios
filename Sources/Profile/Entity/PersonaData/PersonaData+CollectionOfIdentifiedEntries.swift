import Prelude

// MARK: - PersonaData.CollectionOfIdentifiedEntries
extension PersonaData {
	public struct CollectionOfIdentifiedEntries<Value: Sendable & Hashable & Codable & BasePersonaDataEntryProtocol>: Sendable, Hashable, Codable, CustomStringConvertible {
		public private(set) var collection: IdentifiedArrayOf<PersonaData.IdentifiedEntry<Value>>

		public init() {
			self.collection = []
		}

		public init(collection: IdentifiedArrayOf<PersonaData.IdentifiedEntry<Value>> = .init()) throws {
			guard Set(collection.map(\.value)).count == collection.count else {
				throw DuplicateValuesFound()
			}
			self.collection = collection
		}

		public mutating func add(_ field: PersonaData.IdentifiedEntry<Value>) throws {
			guard !contains(where: { $0.value == field.value }) else {
				throw DuplicateValuesFound()
			}
			let (wasInserted, _) = self.collection.append(field)
			guard wasInserted else {
				throw DuplicateIDOfValueFound()
			}
		}

		public mutating func update(_ updated: PersonaData.IdentifiedEntry<Value>) throws {
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
				collection: container.decode(IdentifiedArrayOf<PersonaData.IdentifiedEntry<Value>>.self)
			)
		}

		public var description: String {
			collection.map(\.description).joined(separator: ", ")
		}
	}
}

// MARK: - PersonaData.CollectionOfIdentifiedEntries + RandomAccessCollection
extension PersonaData.CollectionOfIdentifiedEntries: RandomAccessCollection {
	public typealias Element = PersonaData.IdentifiedEntry<Value>

	public typealias Index = IdentifiedArrayOf<PersonaData.IdentifiedEntry<Value>>.Index

	public typealias SubSequence = IdentifiedArrayOf<PersonaData.IdentifiedEntry<Value>>.SubSequence

	public typealias Indices = IdentifiedArrayOf<PersonaData.IdentifiedEntry<Value>>.Indices

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
