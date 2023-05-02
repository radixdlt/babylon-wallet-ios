import Prelude

// MARK: - BabylonDeviceFactorSource
/// This is NOT a `Codable` factor source, this never saved any where, just in memory.
/// It acts a a convenience in code to not have to assert that `kind == .device` and
/// try to access `entityCreatingStorage` which is optional also asserting `parameters` to
/// only declare `curve25519` and `cap26` derivation path.
public struct BabylonDeviceFactorSource: Sendable, Hashable, Identifiable, _FactorSourceProtocol {
	public let kind: FactorSourceKind
	public let id: FactorSourceID
	public let label: FactorSource.Label
	public let description: FactorSource.Description
	public let parameters: FactorSource.Parameters
	public let entityCreatingStorage: FactorSource.Storage.EntityCreating
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

		self.entityCreatingStorage = try factorSource.entityCreatingStorage()
		self.kind = factorSource.kind
		self.addedOn = factorSource.addedOn
		self.lastUsedOn = factorSource.lastUsedOn
		self.label = factorSource.label
		self.description = factorSource.description
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
		.entityCreating(entityCreatingStorage)
	}

	public var hdOnDeviceFactorSource: HDOnDeviceFactorSource {
		.init(
			kind: kind,
			id: id,
			label: label,
			description: description,
			parameters: parameters,
			entityCreatingStorage: entityCreatingStorage,
			addedOn: addedOn,
			lastUsedOn: lastUsedOn
		)
	}

	public var factorSource: FactorSource {
		.init(
			kind: kind,
			id: id,
			label: label,
			description: description,
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
