import Prelude

// MARK: - BabylonDeviceFactorSource
/// This is NOT a `Codable` factor source, this never saved any where, just in memory.
/// It acts a a convenience in code to not have to assert that `kind == .device` and
/// try to access `deviceStorage` which is optional also asserting `parameters` to
/// only declare `curve25519` and `cap26` derivation path.
public struct BabylonDeviceFactorSource: Sendable, Hashable, Identifiable, _FactorSourceProtocol {
	public let kind: FactorSourceKind
	public let id: FactorSourceID
	public let hint: NonEmptyString
	public let parameters: FactorSource.Parameters
	public let deviceStorage: DeviceStorage
	public let addedOn: Date
	public let lastUsedOn: Date

	public init(factorSource: FactorSource) throws {
		guard
			factorSource.kind == .device
		else {
			throw CriticalDisrepancyFactorSourceNotOfDeviceKind()
		}
		guard factorSource.parameters == .babylon else {
			throw CriticalDisrepancyFactorSourceParametersNotBabylon()
		}

		self.deviceStorage = try factorSource.deviceStorage()
		self.kind = factorSource.kind
		self.addedOn = factorSource.addedOn
		self.lastUsedOn = factorSource.lastUsedOn
		self.hint = factorSource.hint
		self.id = factorSource.id
		self.parameters = factorSource.parameters
	}

	public init(hdOnDeviceFactorSource: HDOnDeviceFactorSource) throws {
		try self.init(factorSource: hdOnDeviceFactorSource.factorSource)
	}

	struct CriticalDisrepancyFactorSourceParametersNotBabylon: Swift.Error {}
}

extension BabylonDeviceFactorSource {
	public var storage: FactorSource.Storage? {
		.forDevice(deviceStorage)
	}

	public var hdOnDeviceFactorSource: HDOnDeviceFactorSource {
		.init(
			kind: kind,
			id: id,
			hint: hint,
			parameters: parameters,
			deviceStorage: deviceStorage,
			addedOn: addedOn,
			lastUsedOn: lastUsedOn
		)
	}

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
}

#if DEBUG
extension BabylonDeviceFactorSource {
	public static let previewValue: Self = try! Self(factorSource: .previewValueDevice)
}
#endif // DEBUG
