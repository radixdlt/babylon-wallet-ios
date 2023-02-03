import ClientPrelude
import Cryptography
import ProfileModels

// MARK: - GenesisFactorInstanceDerivationStrategy
public enum GenesisFactorInstanceDerivationStrategy: Sendable, Equatable {
	case loadMnemonicFromKeychainForFactorSource(Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource)

	/// Needed when creating a virtual entity as part of NewProfileThenAccount flow (part of Onboarding),
	/// during which no mnemonic has yet been saved into keychain.
	case useMnemonic(Mnemonic, forFactorSource: Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource)

	public var factorSource: Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource {
		switch self {
		case let .loadMnemonicFromKeychainForFactorSource(factorSource): return factorSource
		case let .useMnemonic(_, factorSource): return factorSource
		}
	}
}

// MARK: - CreateVirtualEntityRequest
public struct CreateVirtualEntityRequest: Sendable, Equatable {
	// if `nil` we will use current networkID
	public let networkID: NetworkID?

	// FIXME: change to shared HDFactorSource
	public let genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy

	public let entityKind: EntityKind
	public let displayName: NonEmpty<String>
	public let keychainAccessFactorSourcesAuthPrompt: String

	public init(
		networkID: NetworkID?,
		genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy,
		entityKind: EntityKind,
		displayName: NonEmpty<String>,
		keychainAccessFactorSourcesAuthPrompt: String
	) throws {
		self.networkID = networkID
		self.genesisFactorInstanceDerivationStrategy = genesisFactorInstanceDerivationStrategy
		self.entityKind = entityKind
		self.displayName = displayName
		self.keychainAccessFactorSourcesAuthPrompt = keychainAccessFactorSourcesAuthPrompt
	}
}

public extension CreateVirtualEntityRequest {
	func getDerivationPathRequest() throws -> GetDerivationPathForNewEntityRequest {
		try .init(networkID: networkID, factorSource: genesisFactorInstanceDerivationStrategy.factorSource, entityKind: entityKind, keyKind: .transactionSigningKey)
	}
}
