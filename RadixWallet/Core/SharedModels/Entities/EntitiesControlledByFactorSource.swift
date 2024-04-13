public typealias NonEmptyAccounts = NonEmpty<IdentifiedArrayOf<Sargon.Account>>

// MARK: - EntitiesControlledByFactorSource
public struct EntitiesControlledByFactorSource: Sendable, Hashable, Identifiable {
	public typealias ID = FactorSourceID
	public var id: ID { deviceFactorSource.id.embed() }
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
	public struct AccountsControlledByKeysOnSameCurve: Equatable, Sendable {
		public struct ID: Sendable, Hashable {
			public let factorSourceID: FactorSourceIdFromHash
			public let isOlympia: Bool
		}

		public let id: ID
		public let accounts: IdentifiedArrayOf<Sargon.Account>
		public let hiddenAccounts: IdentifiedArrayOf<Sargon.Account>
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
	public var babylonAccounts: IdentifiedArrayOf<Sargon.Account> {
		accounts.filter(not(\.isOlympiaAccount)).asIdentified()
	}

	/// hidden
	public var babylonAccountsHidden: IdentifiedArrayOf<Sargon.Account> {
		hiddenAccounts.filter(not(\.isOlympiaAccount)).asIdentified()
	}

	/// Non hidden
	public var olympiaAccounts: IdentifiedArrayOf<Sargon.Account> {
		accounts.filter(\.isOlympiaAccount).asIdentified()
	}

	/// hidden
	public var olympiaAccountsHidden: IdentifiedArrayOf<Sargon.Account> {
		hiddenAccounts.filter(\.isOlympiaAccount).asIdentified()
	}

	public var accounts: [Sargon.Account] { entities.compactMap { try? $0.asAccount() } }
	public var hiddenAccounts: [Sargon.Account] { hiddenEntities.compactMap { try? $0.asAccount() } }
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
			loggerGlobal.error("BDFS with non 24 words mnemonic found, probably this profile originated from Android? Which with 'BDFS Error' with 1.0.0 allowed usage of 12 word Olympia Mnemonic.")
			return false
		}
	}
}

extension FactorSourceProtocol {
	public var isExplicitMain: Bool {
		common.flags.contains(.main)
	}
}
