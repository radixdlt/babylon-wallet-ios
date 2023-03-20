import Prelude

// MARK: - HDOnDeviceFactorSource
/// This is NOT a `Codable` factor source, this never saved any where, just in memory.
/// It acts a a convenience in code to not have to assert that `kind == .device` and
/// try to access `deviceStorage` which is optional.
public struct HDOnDeviceFactorSource: Sendable, Hashable, Identifiable {
	public let kind: FactorSourceKind
	public let id: FactorSourceID
	public let hint: NonEmptyString
	public let parameters: FactorSource.Parameters
	public let storage: DeviceStorage
	public let addedOn: Date
	public let lastUsedOn: Date

	public init(factorSource: FactorSource) throws {
		guard
			factorSource.kind == .device
		else {
			throw CriticalDisrepancyFactorSourceNotOfDeviceKind()
		}

		self.storage = try factorSource.deviceStorage()
		self.kind = factorSource.kind
		self.addedOn = factorSource.addedOn
		self.lastUsedOn = factorSource.lastUsedOn
		self.hint = factorSource.hint
		self.id = factorSource.id
		self.parameters = factorSource.parameters
	}

	struct CriticalDisrepancyFactorSourceNotOfDeviceKind: Swift.Error {}
}

extension HDOnDeviceFactorSource {
	public var factorSource: FactorSource {
		.init(
			kind: kind,
			id: id,
			hint: hint,
			parameters: parameters,
			storage: .forDevice(storage),
			addedOn: addedOn,
			lastUsedOn: lastUsedOn
		)
	}

	public var supportsOlympia: Bool {
		parameters.supportsOlympia
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
