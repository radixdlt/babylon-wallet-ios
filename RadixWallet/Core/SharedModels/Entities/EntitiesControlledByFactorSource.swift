import Sargon

public typealias NonEmptyAccounts = NonEmpty<IdentifiedArrayOf<Account>>

// MARK: - EntitiesControlledByFactorSource
public struct EntitiesControlledByFactorSource: Sendable, Hashable, Identifiable {
	public typealias ID = FactorSourceID
	public var id: ID { deviceFactorSource.id.asGeneral }
	public let entities: [AccountOrPersona]
	public let hiddenEntities: [AccountOrPersona]
	public var isMnemonicPresentInKeychain: Bool
	public var isMnemonicMarkedAsBackedUp: Bool
	public let deviceFactorSource: DeviceFactorSource

	public init(
		entities: [AccountOrPersona],
		hiddenEntities: [AccountOrPersona],
		deviceFactorSource: DeviceFactorSource,
		isMnemonicPresentInKeychain: Bool,
		isMnemonicMarkedAsBackedUp: Bool
	) {
		self.entities = entities
		self.hiddenEntities = hiddenEntities
		self.deviceFactorSource = deviceFactorSource
		self.isMnemonicPresentInKeychain = isMnemonicPresentInKeychain
		self.isMnemonicMarkedAsBackedUp = isMnemonicMarkedAsBackedUp
	}
}

extension EntitiesControlledByFactorSource {
	public struct EntitiesControlledByKeysOnSameCurve: Equatable, Sendable {
		public struct ID: Sendable, Hashable {
			public let factorSourceID: FactorSourceIdFromHash
			public let isOlympia: Bool
		}

		public let id: ID
		public let accounts: IdentifiedArrayOf<Account>
		public let hiddenAccounts: IdentifiedArrayOf<Account>
		public let personas: [Persona]
	}

	public var olympia: EntitiesControlledByKeysOnSameCurve? {
		guard deviceFactorSource.supportsOlympia else { return nil }
		return EntitiesControlledByKeysOnSameCurve(
			id: .init(factorSourceID: deviceFactorSource.id, isOlympia: true),
			accounts: olympiaAccounts,
			hiddenAccounts: olympiaAccountsHidden,
			personas: personas
		)
	}

	public var babylon: EntitiesControlledByKeysOnSameCurve? {
		guard deviceFactorSource.isBDFS else { return nil }
		return EntitiesControlledByKeysOnSameCurve(
			id: .init(factorSourceID: deviceFactorSource.id, isOlympia: false),
			accounts: babylonAccounts,
			hiddenAccounts: babylonAccountsHidden,
			personas: personas
		)
	}

	/// Non hidden
	public var babylonAccounts: IdentifiedArrayOf<Account> {
		accounts.filter(not(\.isLegacy)).asIdentified()
	}

	/// hidden
	public var babylonAccountsHidden: IdentifiedArrayOf<Account> {
		hiddenAccounts.filter(not(\.isLegacy)).asIdentified()
	}

	/// Non hidden
	public var olympiaAccounts: IdentifiedArrayOf<Account> {
		accounts.filter(\.isLegacy).asIdentified()
	}

	/// hidden
	public var olympiaAccountsHidden: IdentifiedArrayOf<Account> {
		hiddenAccounts.filter(\.isLegacy).asIdentified()
	}

	public var accounts: [Account] { entities.compactMap { try? $0.asAccount() } }
	public var hiddenAccounts: [Account] { hiddenEntities.compactMap { try? $0.asAccount() } }
	public var personas: [Persona] { entities.compactMap { try? $0.asPersona() } }
	public var hiddenPersonas: [Persona] { hiddenEntities.compactMap { try? $0.asPersona() } }
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

	public var factorSourceID: FactorSourceIDFromHash {
		deviceFactorSource.id
	}

	public var mnemonicWordCount: BIP39WordCount {
		deviceFactorSource.hint.mnemonicWordCount
	}
}
