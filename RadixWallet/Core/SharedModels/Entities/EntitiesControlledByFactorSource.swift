import Sargon

typealias NonEmptyAccounts = NonEmpty<IdentifiedArrayOf<Account>>

// MARK: - EntitiesControlledByFactorSource
struct EntitiesControlledByFactorSource: Sendable, Hashable, Identifiable {
	typealias ID = FactorSourceID
	var id: ID { deviceFactorSource.id.asGeneral }
	let entities: [AccountOrPersona]
	let hiddenEntities: [AccountOrPersona]
	var isMnemonicPresentInKeychain: Bool
	var isMnemonicMarkedAsBackedUp: Bool
	let deviceFactorSource: DeviceFactorSource

	init(
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
	struct EntitiesControlledByKeysOnSameCurve: Equatable, Sendable {
		struct ID: Sendable, Hashable {
			let factorSourceID: FactorSourceIdFromHash
			let isOlympia: Bool
		}

		let id: ID
		let accounts: IdentifiedArrayOf<Account>
		let hiddenAccounts: IdentifiedArrayOf<Account>
		let personas: [Persona]
	}

	var olympia: EntitiesControlledByKeysOnSameCurve? {
		guard deviceFactorSource.supportsOlympia else { return nil }
		return EntitiesControlledByKeysOnSameCurve(
			id: .init(factorSourceID: deviceFactorSource.id, isOlympia: true),
			accounts: olympiaAccounts,
			hiddenAccounts: olympiaAccountsHidden,
			personas: personas
		)
	}

	var babylon: EntitiesControlledByKeysOnSameCurve? {
		guard deviceFactorSource.isBDFS else { return nil }
		return EntitiesControlledByKeysOnSameCurve(
			id: .init(factorSourceID: deviceFactorSource.id, isOlympia: false),
			accounts: babylonAccounts,
			hiddenAccounts: babylonAccountsHidden,
			personas: personas
		)
	}

	/// Non hidden
	var babylonAccounts: IdentifiedArrayOf<Account> {
		accounts.filter(not(\.isLegacy)).asIdentified()
	}

	/// hidden
	var babylonAccountsHidden: IdentifiedArrayOf<Account> {
		hiddenAccounts.filter(not(\.isLegacy)).asIdentified()
	}

	/// Non hidden
	var olympiaAccounts: IdentifiedArrayOf<Account> {
		accounts.filter(\.isLegacy).asIdentified()
	}

	/// hidden
	var olympiaAccountsHidden: IdentifiedArrayOf<Account> {
		hiddenAccounts.filter(\.isLegacy).asIdentified()
	}

	var accounts: [Account] { entities.compactMap { try? $0.asAccount() } }
	var hiddenAccounts: [Account] { hiddenEntities.compactMap { try? $0.asAccount() } }
	var personas: [Persona] { entities.compactMap { try? $0.asPersona() } }
	var hiddenPersonas: [Persona] { hiddenEntities.compactMap { try? $0.asPersona() } }
}

extension EntitiesControlledByFactorSource {
	/// **B**abylon **D**evice **F**actor **S**ource
	var isBDFS: Bool {
		deviceFactorSource.isBDFS
	}

	var factorSourceID: FactorSourceIDFromHash {
		deviceFactorSource.id
	}

	var mnemonicWordCount: BIP39WordCount {
		deviceFactorSource.hint.mnemonicWordCount
	}
}
