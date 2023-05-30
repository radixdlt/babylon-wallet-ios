import EngineToolkitModels
import Prelude

// MARK: - _EntityCreatingFactorSourceProtocol
public protocol _EntityCreatingFactorSourceProtocol: BaseFactorSourceProtocol {
	var nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork { get }
}

extension _EntityCreatingFactorSourceProtocol {
	public func derivationPathForNextEntity(
		kind entityKind: EntityKind,
		networkID: NetworkID
	) throws -> DerivationPath {
//		try nextDerivationIndicesPerNetwork.derivationPathForNextEntity(kind: entityKind, networkID: networkID)
		try nextDerivationIndicesPerNetwork.derivationPathForNextEntity(kind: entityKind, networkID: networkID)
	}
}

// MARK: - _HDFactorSourceProtocol
public protocol _HDFactorSourceProtocol {}

// MARK: - DeviceFactorSource + _HDFactorSourceProtocol
extension DeviceFactorSource: _HDFactorSourceProtocol {}

// MARK: - LedgerHardwareWalletFactorSource + _HDFactorSourceProtocol
extension LedgerHardwareWalletFactorSource: _HDFactorSourceProtocol {}

// MARK: - EntityCreatingFactorSource
public struct EntityCreatingFactorSource: _EntityCreatingFactorSourceProtocol {
	public static var assertedKind: FactorSourceKind? { nil }
	public static var assertedParameters: FactorSource.CryptoParameters? { nil }
	public let factorSource: FactorSource
	public let nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork

	public init(factorSource: FactorSource) throws {
//		self.factorSource = try Self.validating(factorSource: factorSource)
//		self.entityCreatingStorage = try factorSource.entityCreatingStorage()
		fatalError()
	}
}

extension EntityCreatingFactorSource {
	public func derivationPathForNextEntity(
		kind entityKind: EntityKind,
		networkID: NetworkID
	) throws -> DerivationPath {
		try nextDerivationIndicesPerNetwork.derivationPathForNextEntity(
			kind: entityKind,
			networkID: networkID
		)
	}
}

extension NextDerivationIndicesPerNetwork {
	public func derivationPathForNextEntity(
		kind entityKind: EntityKind,
		networkID: NetworkID
	) throws -> DerivationPath {
		try DerivationPath.forEntity(
			kind: entityKind,
			networkID: networkID,
			index: nextForEntity(kind: entityKind, networkID: networkID)
		)
	}
}

extension NextDerivationIndicesPerNetwork {
	public func nextForEntity(
		kind entityKind: EntityKind,
		networkID: Radix.Network.ID
	) -> Profile.Network.NextDerivationIndices.Index {
		guard let network = self.networks[id: networkID] else {
			return 0
		}
		return network.nextForEntity(kind: entityKind)
	}
}

extension Profile.Network.NextDerivationIndices {
	public func nextForEntity(kind entityKind: EntityKind) -> Index {
		switch entityKind {
		case .identity: return forIdentity
		case .account: return forAccount
		}
	}
}
