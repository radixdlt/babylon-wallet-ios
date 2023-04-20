import EngineToolkitModels
import Prelude

// MARK: - HDOnDeviceFactorSource
/// This is NOT a `Codable` factor source, this never saved any where, just in memory.
/// It acts a a convenience in code to not have to assert that `kind == .device` and
/// if storage exists, we assert that it is `device` storage
public struct HDOnDeviceFactorSource: Sendable, Hashable, Identifiable, _FactorSourceProtocol {
	public let kind: FactorSourceKind
	public let id: FactorSourceID
	public let hint: NonEmptyString
	public let parameters: FactorSource.Parameters
	public var entityCreatingStorage: FactorSource.Storage.EntityCreating?
	public let addedOn: Date
	public let lastUsedOn: Date

	public init(
		kind: FactorSourceKind,
		id: FactorSourceID,
		hint: NonEmptyString,
		parameters: FactorSource.Parameters,
		entityCreatingStorage: FactorSource.Storage.EntityCreating?,
		addedOn: Date,
		lastUsedOn: Date
	) {
		self.kind = kind
		self.id = id
		self.hint = hint
		self.parameters = parameters
		self.entityCreatingStorage = entityCreatingStorage
		self.addedOn = addedOn
		self.lastUsedOn = lastUsedOn
	}

	public init(factorSource: FactorSource) throws {
		guard
			factorSource.kind == .device
		else {
			throw CriticalDisrepancyFactorSourceNotOfDeviceKind()
		}

		if let anyStorage = factorSource.storage {
			// Fail if we get the wrong kind of storage,
			// but OK if nil, which it will be for "olympia" device factor sources.
			self.entityCreatingStorage = try anyStorage.asEntityCreating()
		}
		self.kind = factorSource.kind
		self.addedOn = factorSource.addedOn
		self.lastUsedOn = factorSource.lastUsedOn
		self.hint = factorSource.hint
		self.id = factorSource.id
		self.parameters = factorSource.parameters
	}
}

// MARK: - CriticalDisrepancyFactorSourceNotOfDeviceKind
struct CriticalDisrepancyFactorSourceNotOfDeviceKind: Swift.Error {}

extension HDOnDeviceFactorSource {
	public var factorSource: FactorSource {
		.init(
			kind: kind,
			id: id,
			hint: hint,
			parameters: parameters,
			storage: storage,
			addedOn: addedOn,
			lastUsedOn: lastUsedOn
		)
	}

	public var supportsOlympia: Bool {
		parameters.supportsOlympia
	}

	public var storage: FactorSource.Storage? {
		guard let entityCreatingStorage else { return nil }
		return .entityCreating(entityCreatingStorage)
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
		try! .init(rawValue: .init(uniqueElements: [.previewValue]))!
	}()
}
#endif // DEBUG
