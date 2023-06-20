import Prelude

public typealias AnyIdentifiedPersonaEntry = PersonaData.IdentifiedEntry<PersonaData.Entry>

extension PersonaData.IdentifiedEntry {
	public func embed() -> AnyIdentifiedPersonaEntry {
		.init(id: id, value: value.embed())
	}
}

// MARK: - PersonaData.IdentifiedEntry
extension PersonaData {
	public struct IdentifiedEntry<Kind>: Sendable, Hashable, Codable, Identifiable where Kind: Sendable & Hashable & Codable & BasePersonaDataEntryProtocol {
		public typealias ID = PersonaDataEntryID
		public let id: ID
		public var value: Kind

		public init(
			id: ID? = nil,
			value: Kind
		) {
			@Dependency(\.uuid) var uuid
			self.id = id ?? uuid()
			self.value = value
		}
	}
}
