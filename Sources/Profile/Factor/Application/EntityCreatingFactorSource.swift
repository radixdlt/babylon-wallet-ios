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

// MARK: - _FactorSourceHolderProtocol
public protocol _FactorSourceHolderProtocol:
	BaseFactorSourceProtocol,
	Sendable,
	Hashable,
	Identifiable
{
	var factorSource: any BaseFactorSourceProtocol { get }
}

extension _FactorSourceHolderProtocol {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.id == rhs.id
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(common)
	}
}

extension _FactorSourceHolderProtocol {
	public typealias ID = FactorSourceID
	public var id: ID { common.id }
	public var kind: FactorSourceKind { factorSource.kind }
	public var common: FactorSource.Common { factorSource.common }
}

// MARK: - _ApplicationFactorSource
public protocol _ApplicationFactorSource:
	_FactorSourceHolderProtocol
{
	static var assertedKind: FactorSourceKind? { get }
	static var assertedParameters: FactorSource.CryptoParameters? { get }
//	init(factorSource: FactorSource) throws
	init(factorSource: any BaseFactorSourceProtocol) throws
}

extension _ApplicationFactorSource {
//	public  {
//		try self.init(factorSource: factorSource.embed())
//	}

	public static var assertedParameters: FactorSource.CryptoParameters? { nil }

	public static func validating(factorSource: any BaseFactorSourceProtocol) throws -> any BaseFactorSourceProtocol {
		if
			let expectedFactorSourceKind = Self.assertedKind,
			factorSource.kind != expectedFactorSourceKind
		{
			throw DisrepancyFactorSourceWrongKind(
				expected: expectedFactorSourceKind,
				actual: factorSource.kind
			)
		}

		if
			let expectedParameters = Self.assertedParameters,
			factorSource.cryptoParameters != expectedParameters
		{
			throw DisrepancyFactorSourceWrongParameters(
				expected: expectedParameters,
				actual: factorSource.cryptoParameters
			)
		}
		return factorSource
	}

	public init(_ applicationFactorSource: some _ApplicationFactorSource) throws {
		try self.init(factorSource: applicationFactorSource.factorSource)
	}
}

// MARK: - DisrepancyFactorSourceWrongKind
public struct DisrepancyFactorSourceWrongKind: Swift.Error {
	public let expected: FactorSourceKind
	public let actual: FactorSourceKind
}

// MARK: - DisrepancyFactorSourceWrongParameters
public struct DisrepancyFactorSourceWrongParameters: Swift.Error {
	public let expected: FactorSource.CryptoParameters
	public let actual: FactorSource.CryptoParameters
}

// MARK: - _HDFactorSourceProtocol
public protocol _HDFactorSourceProtocol: BaseFactorSourceProtocol {}

// MARK: - DeviceFactorSource + _HDFactorSourceProtocol
extension DeviceFactorSource: _HDFactorSourceProtocol {}

// MARK: - LedgerHardwareWalletFactorSource + _HDFactorSourceProtocol
extension LedgerHardwareWalletFactorSource: _HDFactorSourceProtocol {}

// MARK: - OffDeviceMnemonicFactorSource + _HDFactorSourceProtocol
extension OffDeviceMnemonicFactorSource: _HDFactorSourceProtocol {}

// MARK: - EntityCreatingFactorSource
public struct EntityCreatingFactorSource: _EntityCreatingFactorSourceProtocol, Sendable {
	public var kind: FactorSourceKind {
		factorSource.kind
	}

	public var common: FactorSource.Common {
		get { factorSource.common }
		set { fatalError("should not be used") }
	}

	public static var assertedKind: FactorSourceKind? { nil }
	public static var assertedParameters: FactorSource.CryptoParameters? { nil }
	public let factorSource: any BaseFactorSourceProtocol
	public let nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork

	public init(factorSource: any BaseFactorSourceProtocol) throws {
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
