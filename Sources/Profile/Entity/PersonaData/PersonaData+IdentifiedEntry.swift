import Prelude

public typealias AnyIdentifiedPersonaEntry = PersonaData.IdentifiedEntry<PersonaData.Entry>

extension PersonaData.IdentifiedEntry {
	public func embed() -> AnyIdentifiedPersonaEntry {
		.init(id: id, value: value.embed())
	}
}

// MARK: - PersonaData.IdentifiedEntry
extension PersonaData {
	public struct IdentifiedEntry<Value>: Sendable, Hashable, Codable, Identifiable where Value: Sendable & Hashable & Codable & BasePersonaDataEntryProtocol {
		public typealias ID = PersonaDataEntryID
		public let id: ID
		public var value: Value

		public init(
			id: ID? = nil,
			value: Value
		) {
			@Dependency(\.uuid) var uuid
			self.id = id ?? uuid()
			self.value = value
		}
	}
}
