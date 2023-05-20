import EngineToolkitModels
import Prelude

// MARK: - _EntityCreatingFactorSourceProtocol
public protocol _EntityCreatingFactorSourceProtocol {
	var entityCreatingStorage: FactorSource.Storage.EntityCreating { get }
}

extension _EntityCreatingFactorSourceProtocol {
	public func derivationPathForNextEntity(
		kind entityKind: EntityKind,
		networkID: NetworkID
	) throws -> DerivationPath {
		try entityCreatingStorage.derivationPathForNextEntity(kind: entityKind, networkID: networkID)
	}
}

// MARK: - _HDFactorSourceProtocol
public protocol _HDFactorSourceProtocol: _ApplicationFactorSource {}

// MARK: - HDOnDeviceFactorSource + _HDFactorSourceProtocol
extension HDOnDeviceFactorSource: _HDFactorSourceProtocol {}

// MARK: - LedgerFactorSource + _HDFactorSourceProtocol
extension LedgerFactorSource: _HDFactorSourceProtocol {}

// MARK: - EntityCreatingFactorSource
public struct EntityCreatingFactorSource: _ApplicationFactorSource, _EntityCreatingFactorSourceProtocol {
	public static var assertedKind: FactorSourceKind? { nil }
	public static var assertedParameters: FactorSource.Parameters? { nil }
	public let factorSource: FactorSource
	public let entityCreatingStorage: FactorSource.Storage.EntityCreating

	public init(factorSource: FactorSource) throws {
		self.factorSource = try Self.validating(factorSource: factorSource)
		self.entityCreatingStorage = try factorSource.entityCreatingStorage()
	}
}

extension EntityCreatingFactorSource {
	public func derivationPathForNextEntity(
		kind entityKind: EntityKind,
		networkID: NetworkID
	) throws -> DerivationPath {
		try entityCreatingStorage.derivationPathForNextEntity(
			kind: entityKind,
			networkID: networkID
		)
	}
}

extension FactorSource.Storage.EntityCreating {
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
