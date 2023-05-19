import Prelude

// MARK: - BabylonDeviceFactorSource
/// This is NOT a `Codable` factor source, this is never saved anywhere, just in memory.
/// It acts a a convenience in code to not have to assert that `kind == .device` and
/// try to access `entityCreatingStorage` which is optional also asserting `parameters` to
/// only declare `curve25519` and `cap26` derivation path.
public struct BabylonDeviceFactorSource: _ApplicationFactorSource, _EntityCreatingFactorSourceProtocol {
	public static let assertedKind: FactorSourceKind? = .device
	public static let assertedParameters: FactorSource.Parameters? = .babylon

	public let factorSource: FactorSource
	public let entityCreatingStorage: FactorSource.Storage.EntityCreating

	public init(factorSource: FactorSource) throws {
		self.factorSource = try Self.validating(factorSource: factorSource)
		self.entityCreatingStorage = try factorSource.entityCreatingStorage()
	}

	public init(hdOnDeviceFactorSource: HDOnDeviceFactorSource) throws {
		try self.init(factorSource: hdOnDeviceFactorSource.factorSource)
	}
}

extension BabylonDeviceFactorSource {
	public var hdOnDeviceFactorSource: HDOnDeviceFactorSource {
		try! .init(factorSource: factorSource)
	}
}

#if DEBUG
extension BabylonDeviceFactorSource {
	public static let previewValue: Self = try! Self(factorSource: .previewValueDevice)
}
#endif // DEBUG
