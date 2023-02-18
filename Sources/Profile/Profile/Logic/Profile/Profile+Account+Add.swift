import Cryptography
import EngineToolkit
import Prelude

extension Profile {
	public struct NetworkAlreadyExists: Swift.Error {}
	public struct AccountDoesNotHaveIndexZero: Swift.Error {}
	public struct DappWasNotConnected: Swift.Error {}

	/// Throws if the network of the account is not new and does not have index 0.
	@discardableResult
	public mutating func add(
		account account0: OnNetwork.Account,
		toNewNetworkWithID networkID: NetworkID
	) throws -> OnNetwork {
		guard !containsNetwork(withID: networkID) else {
			throw NetworkAlreadyExists()
		}
		guard account0.index == 0 else {
			throw AccountDoesNotHaveIndexZero()
		}

		let onNetwork = OnNetwork(
			networkID: networkID,
			accounts: .init(rawValue: .init(uniqueElements: [account0]))!,
			personas: [],
			connectedDapps: []
		)
		try self.perNetwork.add(onNetwork)
		return onNetwork
	}
}

// MARK: Create Account
extension Profile {
	/// Creates a new **Virtual** `Account` without saving it anywhere
	public static func createNewVirtualAccount(
		factorSources: FactorSources,
		accountIndex: Int,
		networkID: NetworkID,
		displayName: NonEmpty<String>,
		createFactorInstance: @escaping CreateFactorInstanceForRequest
	) async throws -> OnNetwork.Account {
		try await OnNetwork.createNewVirtualEntity(
			factorSources: factorSources,
			index: accountIndex,
			networkID: networkID,
			displayName: displayName,
			createFactorInstance: createFactorInstance,
			makeEntity: {
				OnNetwork.Account(
					networkID: networkID,
					address: $0,
					securityState: $1,
					index: $2,
					derivationPath: $3,
					displayName: $4
				)
			}
		)
	}

	/// Creates a new Virtual `Account` **without saving it** anywhere or adding it to the profile.
	public func createNewVirtualAccountWithoutSavingIt(
		networkID: NetworkID,
		accountIndex: Int = 0,
		displayName: NonEmpty<String>,
		mnemonicForFactorSourceByReference: @escaping MnemonicForFactorSourceByReference
	) async throws -> OnNetwork.Account {
		try await Self.createNewVirtualAccount(
			factorSources: self.factorSources,
			accountIndex: accountIndex,
			networkID: networkID,
			displayName: displayName,
			createFactorInstance: mnemonicForFactorSourceByReferenceToCreateFactorInstance(
				includePrivateKey: false,
				mnemonicForFactorSourceByReference
			)
		)
	}
}

extension FactorSources {
	public func onDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource(
		byReference needle: FactorSourceReference
	) -> (any OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource)? {
		switch needle.factorSourceKind {
		case .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind:
			return self.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.first(where: { $0.reference == needle })
		case .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSourceKind:
			return self.secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources.first(where: { $0.reference == needle })
		}
	}
}

// MARK: - CreateAccountError
public enum CreateAccountError: Swift.Error, Equatable {
	case noFactorSourceFoundInProfileForReference(FactorSourceReference)
	case noMnemonicFoundInKeychainForReference(FactorSourceReference)
}

// MARK: Add Virtual Account
extension Profile {
	/// Creates a new **Virtual** `Account` and saves it into the profile, by trying to load
	/// mnemonics using `mnemonicForFactorSourceByReference`, to create factor instances for this new account.
	@discardableResult
	public mutating func createNewVirtualAccount(
		networkID: NetworkID,
		displayName: NonEmpty<String>,
		mnemonicForFactorSourceByReference: @escaping MnemonicForFactorSourceByReference
	) async throws -> OnNetwork.Account {
		try await createNewVirtualAccount(
			networkID: networkID,
			displayName: displayName,
			createFactorInstance: mnemonicForFactorSourceByReferenceToCreateFactorInstance(
				includePrivateKey: false,
				mnemonicForFactorSourceByReference
			)
		)
	}

	/// Creates a new **Virtual** `Account` and saves it into the profile.
	@discardableResult
	public mutating func createNewVirtualAccount(
		networkID: NetworkID,
		displayName: NonEmpty<String>,
		createFactorInstance: @escaping CreateFactorInstanceForRequest
	) async throws -> OnNetwork.Account {
		let account = try await self.creatingNewVirtualAccount(
			networkID: networkID,
			displayName: displayName,
			createFactorInstance: createFactorInstance
		)

		try await addAccount(account)

		return account
	}

	/// Saves an `Account` into the profile
	public mutating func addAccount(
		_ account: OnNetwork.Account
	) async throws {
		let networkID = account.networkID
		// can be nil if this is a new network
		let maybeNetwork = try? onNetwork(id: networkID)

		if var onNetwork = maybeNetwork {
			guard !onNetwork.accounts.contains(where: { $0 == account }) else {
				throw AccountAlreadyExists()
			}
			onNetwork.accounts.appendAccount(account)
			try updateOnNetwork(onNetwork)
		} else {
			let onNetwork = OnNetwork(
				networkID: networkID,
				accounts: .init(rawValue: .init(uniqueElements: [account]))!,
				personas: [],
				connectedDapps: []
			)
			try perNetwork.add(onNetwork)
		}
	}

	/// Saves a `ConnectedDapp` into the profile
	@discardableResult
	public mutating func addConnectedDapp(
		_ unvalidatedConnectedDapp: OnNetwork.ConnectedDapp
	) async throws -> OnNetwork.ConnectedDapp {
		let connectedDapp = try validateAuthorizedPersonas(of: unvalidatedConnectedDapp)
		let networkID = connectedDapp.networkID
		var network = try onNetwork(id: networkID)
		guard !network.connectedDapps.contains(where: { $0.dAppDefinitionAddress == connectedDapp.dAppDefinitionAddress }) else {
			throw ConnectedDappAlreadyExists()
		}
		guard network.connectedDapps.updateOrAppend(connectedDapp) == nil else {
			fatalError("Incorrect implementation, should have been a new ConnectedDapp")
		}
		try updateOnNetwork(network)
		return connectedDapp
	}

	/// Forgets  a `ConnectedDapp`
	public mutating func forgetConnectedDapp(
		_ connectedDappID: OnNetwork.ConnectedDapp.ID,
		on networkID: NetworkID
	) async throws {
		var network = try onNetwork(id: networkID)
		guard network.connectedDapps.remove(id: connectedDappID) != nil else {
			throw DappWasNotConnected()
		}

		try updateOnNetwork(network)
	}

	@discardableResult
	private func validateAuthorizedPersonas(of connectedDapp: OnNetwork.ConnectedDapp) throws -> OnNetwork.ConnectedDapp {
		let networkID = connectedDapp.networkID
		let network = try onNetwork(id: networkID)

		// Validate that all Personas are known and that every Field.ID is known
		// for each Persona.
		struct ConnectedDappReferencesUnknownPersonas: Swift.Error {}
		struct ConnectedDappReferencesUnknownPersonaField: Swift.Error {}
		for personaNeedle in connectedDapp.referencesToAuthorizedPersonas {
			guard let persona = network.personas.first(where: { $0.address == personaNeedle.identityAddress }) else {
				throw ConnectedDappReferencesUnknownPersonas()
			}
			let fieldIDNeedles = Set(personaNeedle.fieldIDs)
			let fieldIDHaystack = Set(persona.fields.map(\.id))
			guard fieldIDHaystack.isSuperset(of: fieldIDNeedles) else {
				throw ConnectedDappReferencesUnknownPersonaField()
			}
		}

		// Validate that all Accounts are known
		let accountAddressNeedles: Set<AccountAddress> = Set(
			connectedDapp.referencesToAuthorizedPersonas.flatMap {
				$0.sharedAccounts?.accountsReferencedByAddress ?? []
			}
		)
		let accountAddressHaystack = Set(network.accounts.map(\.address))
		guard accountAddressHaystack.isSuperset(of: accountAddressNeedles) else {
			struct ConnectedDappReferencesUnknownAccount: Swift.Error {}
			throw ConnectedDappReferencesUnknownAccount()
		}
		// All good
		return connectedDapp
	}

	/// Updates a `ConnectedDapp` in the profile
	public mutating func updateConnectedDapp(
		_ unvalidatedConnectedDapp: OnNetwork.ConnectedDapp
	) async throws {
		let connectedDapp = try validateAuthorizedPersonas(of: unvalidatedConnectedDapp)
		let networkID = connectedDapp.networkID
		var network = try onNetwork(id: networkID)
		guard network.connectedDapps.contains(where: { $0.dAppDefinitionAddress == connectedDapp.dAppDefinitionAddress }) else {
			throw ConnectedDappDoesNotExists()
		}
		guard network.connectedDapps.updateOrAppend(connectedDapp) != nil else {
			fatalError("Incorrect implementation, should have been an existing ConnectedDapp")
		}
		try updateOnNetwork(network)
	}

	public mutating func disconnectPersonaFromDapp(
		_ personaID: OnNetwork.Persona.ID,
		dAppID: OnNetwork.ConnectedDapp.ID,
		networkID: NetworkID
	) async throws {
		var network = try onNetwork(id: networkID)
		guard var connectedDapp = network.connectedDapps[id: dAppID] else {
			throw ConnectedDappDoesNotExists()
		}

		guard connectedDapp.referencesToAuthorizedPersonas.remove(id: personaID) != nil else {
			throw PersonaNotConnected()
		}

		guard network.connectedDapps.updateOrAppend(connectedDapp) != nil else {
			fatalError("Incorrect implementation, should have been an existing ConnectedDapp")
		}
		try updateOnNetwork(network)
	}

	/// Creates a new **Virtual** `Account` without saving it into the profile.
	public func creatingNewVirtualAccount(
		networkID: NetworkID,
		displayName: NonEmpty<String>,
		mnemonicForFactorSourceByReference: @escaping MnemonicForFactorSourceByReference
	) async throws -> OnNetwork.Account {
		try await creatingNewVirtualAccount(
			networkID: networkID,
			displayName: displayName,
			createFactorInstance: mnemonicForFactorSourceByReferenceToCreateFactorInstance(
				includePrivateKey: false,
				mnemonicForFactorSourceByReference
			)
		)
	}

	/// Creates a new **Virtual** `Account` without saving it into the profile.
	public func creatingNewVirtualAccount(
		networkID: NetworkID,
		displayName: NonEmpty<String>,
		createFactorInstance: @escaping CreateFactorInstanceForRequest
	) async throws -> OnNetwork.Account {
		let maybeNetworkNetwork = try? onNetwork(id: networkID)

		let account = try await Self.createNewVirtualAccount(
			factorSources: self.factorSources,
			accountIndex: maybeNetworkNetwork?.accounts.count ?? 0,
			networkID: networkID,
			displayName: displayName,
			createFactorInstance: createFactorInstance
		)

		return account
	}
}

extension Profile {
	internal static func mnemonicForFactorSourceByReferenceToCreateFactorInstance(
		factorSources: FactorSources,
		includePrivateKey: Bool,
		_ mnemonicForFactorSourceByReference: @escaping MnemonicForFactorSourceByReference
	) -> CreateFactorInstanceForRequest {
		{ createFactorInstanceRequest in
			switch createFactorInstanceRequest {
			case let .fromNonHardwareHierarchicalDeterministicMnemonicFactorSource(nonHWHDRequest):
				guard let factorSource = factorSources.onDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource(byReference: nonHWHDRequest.reference) else {
					throw CreateAccountError.noFactorSourceFoundInProfileForReference(nonHWHDRequest.reference)
				}
				precondition(factorSource.reference == nonHWHDRequest.reference)
				guard let mnemonic = try await mnemonicForFactorSourceByReference(nonHWHDRequest.reference) else {
					throw CreateAccountError.noMnemonicFoundInKeychainForReference(factorSource.reference)
				}
				return try await factorSource.createAnyFactorInstanceForResponse(
					input: CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput(
						mnemonic: mnemonic,
						derivationPath: nonHWHDRequest.derivationPath,
						includePrivateKey: includePrivateKey
					)
				)
			}
		}
	}

	internal func mnemonicForFactorSourceByReferenceToCreateFactorInstance(
		includePrivateKey: Bool,
		_ mnemonicForFactorSourceByReference: @escaping MnemonicForFactorSourceByReference
	) -> CreateFactorInstanceForRequest {
		Self.mnemonicForFactorSourceByReferenceToCreateFactorInstance(
			factorSources: self.factorSources,
			includePrivateKey: includePrivateKey,
			mnemonicForFactorSourceByReference
		)
	}
}

// MARK: - PersonaNotConnected
struct PersonaNotConnected: Swift.Error {}

public typealias MnemonicForFactorSourceByReference = @Sendable (FactorSourceReference) async throws -> Mnemonic?
