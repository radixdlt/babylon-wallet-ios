import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - GenesisFactorInstanceDerivationStrategy
// FIXME: move to some ProfileBaseClient package used AccountsClient, PersonasClient etc.

public enum GenesisFactorInstanceDerivationStrategy: Sendable, Hashable {
	case loadMnemonicFromKeychainForFactorSource(FactorSource)

	case useEphemeralPrivateProfile(EphemeralPrivateProfile)

	public var factorSource: FactorSource {
		switch self {
		case let .loadMnemonicFromKeychainForFactorSource(factorSource): return factorSource
		case let .useEphemeralPrivateProfile(ephemeralPrivateProfile): return ephemeralPrivateProfile.privateFactorSource.factorSource
		}
	}
}

// MARK: - CreateVirtualEntityRequest
public protocol CreateVirtualEntityRequest: Sendable {
	// if `nil` we will use current networkID
	var networkID: NetworkID? { get }

	// FIXME: change to shared HDFactorSource
	var genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy { get }

	var curve: Slip10Curve { get }
	var entityKind: EntityKind { get }
	var displayName: NonEmpty<String> { get }

//	public init(
//		curve: Slip10Curve,
//		networkID: NetworkID?,
//		genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy,
//		entityKind: EntityKind,
//		displayName: NonEmpty<String>
//	) throws {
//		self.curve = curve
//		self.networkID = networkID
//		self.genesisFactorInstanceDerivationStrategy = genesisFactorInstanceDerivationStrategy
//		self.entityKind = entityKind
//		self.displayName = displayName
//	}
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
