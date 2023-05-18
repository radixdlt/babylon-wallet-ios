import EngineToolkitModels
import Prelude

// MARK: - HDOnDeviceFactorSource
/// This is NOT a `Codable` factor source, this is never saved anywhere, just in memory.
/// It acts a a convenience in code to not have to assert that `kind == .device` and
/// if storage exists, we assert that it is `device` storage
public struct HDOnDeviceFactorSource: _ApplicationFactorSource {
	public static let assertedKind: FactorSourceKind = .device

	public let factorSource: FactorSource
	public let entityCreatingStorage: FactorSource.Storage.EntityCreating

	public init(factorSource: FactorSource) throws {
		self.factorSource = try Self.validating(factorSource: factorSource)
		self.entityCreatingStorage = try factorSource.entityCreatingStorage()
	}
}

public typealias HDOnDeviceFactorSources = NonEmpty<IdentifiedArrayOf<HDOnDeviceFactorSource>>

#if DEBUG
extension HDOnDeviceFactorSource {
	public static let previewValue: Self = try! Self(factorSource: .previewValueDevice)
}
#endif // DEBUG

#if DEBUG
extension HDOnDeviceFactorSources {
	public static let previewValues: Self = {
		.init(rawValue: .init(uniqueElements: [.previewValue]))!
	}()
}
#endif // DEBUG
