import ClientPrelude
import Cryptography
import ProfileModels

// MARK: - GenesisFactorInstanceDerivationStrategy
public enum GenesisFactorInstanceDerivationStrategy: Sendable, Hashable {
	case loadMnemonicFromKeychainForFactorSource(FactorSource)

	case useOnboardingWallet(OnboardingWallet)

	public var factorSource: FactorSource {
		switch self {
		case let .loadMnemonicFromKeychainForFactorSource(factorSource): return factorSource
		case let .useOnboardingWallet(onboardingWallet): return onboardingWallet.privateFactorSource.factorSource
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

extension CreateVirtualEntityRequest {
	public func getDerivationPathRequest() throws -> GetDerivationPathForNewEntityRequest {
		try .init(
			networkID: networkID,
			factorSource: genesisFactorInstanceDerivationStrategy.factorSource,
			entityKind: entityKind,
			keyKind: .transactionSigningKey
		)
	}
}
