import EngineToolkit
import Foundation

public extension Profile {
	struct NetworkAlreadyExists: Swift.Error {}
	struct AccountDoesNotHaveIndexZero: Swift.Error {}

	/// Throws if the network of the account is not new and does not have index 0.
	@discardableResult
	mutating func add(
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
			accounts: .init(rawValue: .init([account0]))!,
			personas: [],
			connectedDapps: []
		)
		try self.perNetwork.add(onNetwork)
		return onNetwork
	}
}

// MARK: Create Account
public extension Profile {
	/// Creates a new **Virtual** `Account` without saving it anywhere
	static func createNewVirtualAccount(
		factorSources: FactorSources,
		accountIndex: Int,
		networkID: NetworkID,
		displayName: String? = nil,
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
	func createNewVirtualAccountWithoutSavingIt(
		networkID: NetworkID,
		accountIndex: Int = 0,
		displayName: String?,
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

public extension FactorSources {
	func onDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource(
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

import Mnemonic

// MARK: - CreateAccountError
public enum CreateAccountError: Swift.Error, Equatable {
	case noFactorSourceFoundInProfileForReference(FactorSourceReference)
	case noMnemonicFoundInKeychainForReference(FactorSourceReference)
}

// MARK: Add Virtual Account
public extension Profile {
	/// Creates a new **Virtual** `Account` and saves it into the profile, by trying to load
	/// mnemonics using `mnemonicForFactorSourceByReference`, to create factor instances for this new account.
	@discardableResult
	mutating func createNewVirtualAccount(
		networkID: NetworkID,
		displayName: String? = nil,
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
	mutating func createNewVirtualAccount(
		networkID: NetworkID,
		displayName: String? = nil,
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

		if var onNetwork = maybeNetworkNetwork {
			onNetwork.accounts.appendAccount(account)
			try updateOnNetwork(onNetwork)
		} else {
			let onNetwork = OnNetwork(
				networkID: networkID,
				accounts: .init(rawValue: .init([account]))!,
				personas: [],
				connectedDapps: []
			)
			try perNetwork.add(onNetwork)
		}

		return account
	}
}

internal extension Profile {
	func mnemonicForFactorSourceByReferenceToCreateFactorInstance(
		includePrivateKey: Bool,
		_ mnemonicForFactorSourceByReference: @escaping MnemonicForFactorSourceByReference
	) -> CreateFactorInstanceForRequest {
		{ [factorSources] createFactorInstanceRequest in
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
}

public typealias MnemonicForFactorSourceByReference = @Sendable (FactorSourceReference) async throws -> Mnemonic?
