public typealias NonEmptyAccounts = NonEmpty<IdentifiedArrayOf<Profile.Network.Account>>

// MARK: - EntitiesControlledByFactorSource
public struct EntitiesControlledByFactorSource: Sendable, Hashable, Identifiable {
	public typealias ID = FactorSourceID
	public var id: ID { deviceFactorSource.id.embed() }
	public let entities: [EntityPotentiallyVirtual]
	public let hiddenEntities: [EntityPotentiallyVirtual]
	public var isMnemonicPresentInKeychain: Bool
	public var isMnemonicMarkedAsBackedUp: Bool
	public let deviceFactorSource: DeviceFactorSource

	public init(
		entities: [EntityPotentiallyVirtual],
		hiddenEntities: [EntityPotentiallyVirtual],
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
	public struct AccountsControlledByKeysOnSameCurve: Equatable, Sendable {
		public struct ID: Sendable, Hashable {
			public let factorSourceID: FactorSource.ID.FromHash
			public let isOlympia: Bool
		}

		public let id: ID
		public let accounts: IdentifiedArrayOf<Profile.Network.Account>
		public let hiddenAccounts: IdentifiedArrayOf<Profile.Network.Account>
	}

	public var olympia: AccountsControlledByKeysOnSameCurve? {
		guard deviceFactorSource.supportsOlympia else { return nil }
		return AccountsControlledByKeysOnSameCurve(
			id: .init(factorSourceID: deviceFactorSource.id, isOlympia: true),
			accounts: olympiaAccounts,
			hiddenAccounts: olympiaAccountsHidden
		)
	}

	public var babylon: AccountsControlledByKeysOnSameCurve? {
		guard deviceFactorSource.isBDFS else { return nil }
		return AccountsControlledByKeysOnSameCurve(
			id: .init(factorSourceID: deviceFactorSource.id, isOlympia: false),
			accounts: babylonAccounts,
			hiddenAccounts: babylonAccountsHidden
		)
	}

	/// Non hidden
	public var babylonAccounts: IdentifiedArrayOf<Profile.Network.Account> {
		accounts.filter(not(\.isOlympiaAccount)).asIdentifiable()
	}

	/// hidden
	public var babylonAccountsHidden: IdentifiedArrayOf<Profile.Network.Account> {
		hiddenAccounts.filter(not(\.isOlympiaAccount)).asIdentifiable()
	}

	/// Non hidden
	public var olympiaAccounts: IdentifiedArrayOf<Profile.Network.Account> {
		accounts.filter(\.isOlympiaAccount).asIdentifiable()
	}

	/// hidden
	public var olympiaAccountsHidden: IdentifiedArrayOf<Profile.Network.Account> {
		hiddenAccounts.filter(\.isOlympiaAccount).asIdentifiable()
	}

	public var accounts: [Profile.Network.Account] { entities.compactMap { try? $0.asAccount() } }
	public var hiddenAccounts: [Profile.Network.Account] { hiddenEntities.compactMap { try? $0.asAccount() } }
	public var personas: [Profile.Network.Persona] { entities.compactMap { try? $0.asPersona() } }
	public var hiddenPersonas: [Profile.Network.Persona] { hiddenEntities.compactMap { try? $0.asPersona() } }
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
		guard supportsBabylon else { return false }
		if hint.mnemonicWordCount == .twentyFour {
			return true
		} else {
			loggerGlobal.notice("BDFS with non 24 words mnemonic found, probably this profile originated from Android? Which with 'BDFS Error' with 1.0.0 allowed usage of 12 word Olympia Mnemonic.")
			return false
		}
	}
}

extension FactorSourceProtocol {
	public var isExplicitMain: Bool {
		common.flags.contains(.main)
	}
}
