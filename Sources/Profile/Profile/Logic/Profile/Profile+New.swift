import Cryptography
import EngineToolkit
import Prelude
import ProfileModels

// MARK: - NoInstance
// extension Profile {
//	public enum AccountCreationStrategy: Sendable, Equatable {
//		case createAccountOnDefaultNetwork(named: NonEmpty<String>)
//		case noAccountThusNoOnNetwork
//	}
//
//	public static func new(
//		networkAndGateway: AppPreferences.NetworkAndGateway,
//		mnemonic: Mnemonic,
//		bip39Passphrase: String = "",
//		accountCreationStrategy: AccountCreationStrategy = .noAccountThusNoOnNetwork
//	) async throws -> Self {
//        fixMultifactor()
////		let factorSource = try FactorSource(
////			mnemonic: mnemonic,
////			bip39Passphrase: bip39Passphrase
////		)
////
////		switch accountCreationStrategy {
////		case let .createAccountOnDefaultNetwork(accountName):
////			let createFactorInstance: CreateFactorInstanceForRequest = { (createFactorInstanceRequest: CreateFactorInstanceRequest) async throws -> AnyCreateFactorInstanceForResponse? in
////				switch createFactorInstanceRequest {
////				case let .fromNonHardwareHierarchicalDeterministicMnemonicFactorSource(nonHWHDRequest):
////					guard factorSource.reference == nonHWHDRequest.reference else {
////						return nil
////					}
////					let createFactorInstanceForResponse = try await factorSource.createInstance(
////						input: .init(
////							mnemonic: mnemonic,
////							bip39Passphrase: bip39Passphrase,
////							derivationPath: nonHWHDRequest.derivationPath,
////							includePrivateKey: false
////						)
////					)
////					return try createFactorInstanceForResponse.eraseToAny()
////				}
////			}
////
////			return try await Self.new(
////				networkAndGateway: networkAndGateway,
////				factorSource: factorSource, accountCreationFromFactorInstanceStrategy: .createAccountOnDefaultNetwork(
////					named: accountName,
////					createFactorInstance: createFactorInstance
////				)
////			)
////		case .noAccountThusNoOnNetwork:
////			return try await Self.new(
////				networkAndGateway: networkAndGateway,
////				factorSource: factorSource, accountCreationFromFactorInstanceStrategy: .noAccountThusNoOnNetwork
////			)
////		}
//	}
//
//	public enum AccountCreationFromFactorInstanceStrategy: Sendable {
//		case createAccountOnDefaultNetwork(named: NonEmpty<String>, createFactorInstance: CreateFactorInstanceForRequest)
//		case noAccountThusNoOnNetwork
//	}
//
//	public static func new(
//		networkAndGateway: AppPreferences.NetworkAndGateway,
//		factorSource: FactorSource,
//		accountCreationFromFactorInstanceStrategy: AccountCreationFromFactorInstanceStrategy
//	) async throws -> Self {
//		let network = networkAndGateway.network
//		let networkID = network.id
//		let nonEmptyFactorSource = NonEmpty(
//			rawValue: IdentifiedArrayOf(uniqueElements: [factorSource])
//		)!
//
//		let factorSources = FactorSources(curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources: nonEmptyFactorSource)
//
//		let appPreferences = AppPreferences(
//			display: .default,
//			p2pClients: [],
//			networkAndGateway: networkAndGateway
//		)
//
//		switch accountCreationFromFactorInstanceStrategy {
//		case .noAccountThusNoOnNetwork:
//			return Self(
//				factorSources: factorSources,
//				appPreferences: appPreferences,
//				perNetwork: .init(dictionary: .init())
//			)
//		case let .createAccountOnDefaultNetwork(accountName, createFactorInstance):
//			let account0 = try await Self.createNewVirtualAccount(
//				factorSources: factorSources,
//				accountIndex: 0,
//				networkID: networkID,
//				displayName: accountName,
//				createFactorInstance: createFactorInstance
//			)
//
//			let onNetwork = OnNetwork(
//				networkID: networkID,
//				accounts: .init(rawValue: .init(uniqueElements: [account0]))!,
//				personas: [],
//				connectedDapps: []
//			)
//
//			return Self(
//				factorSources: factorSources,
//				appPreferences: appPreferences,
//				perNetwork: .init(onNetwork: onNetwork)
//			)
//		}
//	}
// }

internal struct NoInstance: Swift.Error {}

// MARK: - FailedToFindFactorSource
internal struct FailedToFindFactorSource: Swift.Error {}

extension Profile {
	internal mutating func updateOnNetwork(_ onNetwork: OnNetwork) throws {
		try perNetwork.update(onNetwork)
	}
}

extension Profile {
	public func onNetwork(id needle: NetworkID) throws -> OnNetwork {
		try perNetwork.onNetwork(id: needle)
	}

	public func containsNetwork(withID networkID: NetworkID) -> Bool {
		(try? onNetwork(id: networkID)) != nil
	}
}

// MARK: - WrongAddressType
struct WrongAddressType: Swift.Error {}

// MARK: - AccountAlreadyExists
struct AccountAlreadyExists: Swift.Error {}

// MARK: - ConnectedDappAlreadyExists
struct ConnectedDappAlreadyExists: Swift.Error {}

// MARK: - ConnectedDappDoesNotExists
struct ConnectedDappDoesNotExists: Swift.Error {}

// MARK: - PersonaAlreadyExists
struct PersonaAlreadyExists: Swift.Error {}
