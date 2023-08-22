import Cryptography
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

extension EntitiesControlledByFactorSource {
	public var isSkippable: Bool {
		deviceFactorSource.supportsOlympia
	}

	public var factorSourceID: FactorSourceID.FromHash {
		deviceFactorSource.id
	}

	public var mnemonicWordCount: BIP39.WordCount {
		deviceFactorSource.hint.mnemonicWordCount
	}
}
