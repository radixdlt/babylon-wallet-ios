// MARK: - EntitiesControlledByFactorSource
public struct EntitiesControlledByFactorSource: Sendable, Hashable, Identifiable {
	public typealias ID = FactorSourceID
	public var id: ID { deviceFactorSource.id.embed() }
	public let entities: [EntityPotentiallyVirtual]
	public var isMnemonicPresentInKeychain: Bool
	public var isMnemonicMarkedAsBackedUp: Bool
	public let deviceFactorSource: DeviceFactorSource

	public init(
		entities: [EntityPotentiallyVirtual],
		deviceFactorSource: DeviceFactorSource,
		isMnemonicPresentInKeychain: Bool,
		isMnemonicMarkedAsBackedUp: Bool
	) {
		self.entities = entities
		self.deviceFactorSource = deviceFactorSource
		self.isMnemonicPresentInKeychain = isMnemonicPresentInKeychain
		self.isMnemonicMarkedAsBackedUp = isMnemonicMarkedAsBackedUp
	}
}

extension EntitiesControlledByFactorSource {
	public var accounts: [Profile.Network.Account] { entities.compactMap { try? $0.asAccount() } }
	public var personas: [Profile.Network.Persona] { entities.compactMap { try? $0.asPersona() } }
}

extension EntitiesControlledByFactorSource {
	/// **B**abylon **D**evice **F**actor **S**ource
	public var isExplicitMainBDFS: Bool {
		deviceFactorSource.isExplicitMainBDFS
	}

	/// **B**abylon **D**evice **F**actor **S**ource
	public var isBDFS: Bool {
		deviceFactorSource.isBDFS
	}

	public var isExplicitMain: Bool {
		deviceFactorSource.isExplicitMain
	}

	public var factorSourceID: FactorSourceID.FromHash {
		deviceFactorSource.id
	}

	public var mnemonicWordCount: BIP39.WordCount {
		deviceFactorSource.hint.mnemonicWordCount
	}
}

extension DeviceFactorSource {
	/// **B**abylon **D**evice **F**actor **S**ource
	public var isExplicitMainBDFS: Bool {
		isBDFS && isExplicitMain
	}

	/// **B**abylon **D**evice **F**actor **S**ource
	public var isBDFS: Bool {
		!supportsOlympia
	}
}

extension FactorSourceProtocol {
	public var isExplicitMain: Bool {
		common.flags.contains(.main)
	}
}
