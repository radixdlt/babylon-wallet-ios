import EngineToolkit
public typealias AnyIdentifiedPersonaEntry = PersonaData.IdentifiedEntry<PersonaData.Entry>

extension PersonaData.IdentifiedEntry {
	public func embed() -> AnyIdentifiedPersonaEntry {
		.init(id: id, value: value.embed())
	}
}

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
