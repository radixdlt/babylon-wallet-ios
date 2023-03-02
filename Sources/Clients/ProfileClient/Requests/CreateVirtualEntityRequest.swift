import ClientPrelude
import Cryptography
import ProfileModels

// MARK: - GenesisFactorInstanceDerivationStrategy
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
public struct CreateVirtualEntityRequest: Sendable, Equatable {
	// if `nil` we will use current networkID
	public let networkID: NetworkID?

	// FIXME: change to shared HDFactorSource
	public let genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy

	public let curve: Slip10Curve
	public let entityKind: EntityKind
	public let displayName: NonEmpty<String>

	public init(
		curve: Slip10Curve,
		networkID: NetworkID?,
		genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy,
		entityKind: EntityKind,
		displayName: NonEmpty<String>
	) throws {
		self.curve = curve
		self.networkID = networkID
		self.genesisFactorInstanceDerivationStrategy = genesisFactorInstanceDerivationStrategy
		self.entityKind = entityKind
		self.displayName = displayName
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
