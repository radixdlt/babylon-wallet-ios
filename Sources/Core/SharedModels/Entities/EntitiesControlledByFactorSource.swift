import Prelude

// MARK: - EntitiesControlledByFactorSource
public struct EntitiesControlledByFactorSource: Sendable, Hashable, Identifiable {
	public typealias ID = FactorSourceID
	public var id: ID { deviceFactorSource.id.embed() }
	public let entities: [EntityPotentiallyVirtual]
	public let deviceFactorSource: DeviceFactorSource

	public init(entities: [EntityPotentiallyVirtual], deviceFactorSource: DeviceFactorSource) {
		self.entities = entities
		self.deviceFactorSource = deviceFactorSource
	}
}

extension EntitiesControlledByFactorSource {
	public var accounts: [Profile.Network.Account] { entities.compactMap { try? $0.asAccount() } }
	public var personas: [Profile.Network.Persona] { entities.compactMap { try? $0.asPersona() } }
}
