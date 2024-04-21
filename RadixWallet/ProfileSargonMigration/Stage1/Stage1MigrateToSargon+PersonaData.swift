import Foundation
import Sargon

extension PersonaData {
	public init() {
		self.init(name: nil, phoneNumbers: .init(collection: []), emailAddresses: .init(collection: []))
	}

	public static var `default`: Self {
		self.init()
	}
}

extension PersonaData {
	public var entries: [AnyIdentifiedPersonaEntry] {
		var sequence: [AnyIdentifiedPersonaEntry?] = []
		sequence.append(name?.embed())
		sequence.append(contentsOf: emailAddresses.collection.map { $0.embed() })
		sequence.append(contentsOf: phoneNumbers.collection.map { $0.embed() })
		return sequence.compactMap { $0 }
	}
}

public typealias AnyIdentifiedPersonaEntry = PersonaData.IdentifiedEntry<PersonaData.Entry>

// MARK: - PersonaData.IdentifiedEntry
extension PersonaData {
	public struct IdentifiedEntry<Value>: Sendable, Hashable, Codable, Identifiable, CustomStringConvertible where Value: Sendable & Hashable & Codable & BasePersonaDataEntryProtocol {
		public typealias ID = PersonaDataEntryID
		public let id: ID
		public var value: Value

		public init(
			id: ID,
			value: Value
		) {
			self.id = id
			self.value = value
		}

		public var description: String {
			"""
			\(value)
			id: \(id)
			"""
		}
	}
}
