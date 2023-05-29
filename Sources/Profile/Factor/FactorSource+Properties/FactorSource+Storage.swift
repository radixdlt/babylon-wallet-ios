import Prelude

// MARK: - FactorSource.Storage
extension FactorSource {
	public enum Storage: Sendable, Hashable, Codable {
		/// EntityCreating
		case entityCreating(FactorSource.Storage.EntityCreating)

		case offDeviceMnemonic(FactorSource.Storage.OffDeviceMnemonic)
	}
}

extension FactorSource.Storage {
	public var entityCreating: FactorSource.Storage.EntityCreating? {
		guard case let .entityCreating(storage) = self else {
			return nil
		}
		return storage
	}

	public func asEntityCreating() throws -> FactorSource.Storage.EntityCreating {
		guard let entityCreating else {
			throw WasNotDeviceFactorSource()
		}
		return entityCreating
	}
}

// MARK: - WasNotDeviceFactorSource
struct WasNotDeviceFactorSource: Swift.Error {}

extension FactorSource {
	public func entityCreatingStorage() throws -> FactorSource.Storage.EntityCreating {
		guard let storage else {
			throw WasNotDeviceFactorSource()
		}
		return try storage.asEntityCreating()
	}
}

// MARK: Codable
extension FactorSource.Storage {
	private enum Discriminator: String, Codable {
		case entityCreating
		case offDeviceMnemonic
	}

	private var discriminator: Discriminator {
		switch self {
		case .entityCreating: return .entityCreating
		case .offDeviceMnemonic: return .offDeviceMnemonic
		}
	}

	private enum CodingKeys: String, CodingKey {
		case discriminator, entityCreatingStorage, offDeviceMnemonic
	}

	public func encode(to encoder: Encoder) throws {
		var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
		try keyedContainer.encode(discriminator, forKey: .discriminator)
		switch self {
		case let .entityCreating(entityCreatingStorage):
			try keyedContainer.encode(entityCreatingStorage, forKey: .entityCreatingStorage)
		case let .offDeviceMnemonic(offDeviceMnemonic):
			try keyedContainer.encode(offDeviceMnemonic, forKey: .offDeviceMnemonic)
		}
	}

	public init(from decoder: Decoder) throws {
		let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try keyedContainer.decode(Discriminator.self, forKey: .discriminator)
		switch discriminator {
		case .entityCreating:
			self = try .entityCreating(
				keyedContainer.decode(FactorSource.Storage.EntityCreating.self, forKey: .entityCreatingStorage)
			)
		case .offDeviceMnemonic:
			self = try .offDeviceMnemonic(
				keyedContainer.decode(FactorSource.Storage.OffDeviceMnemonic.self, forKey: .offDeviceMnemonic)
			)
		}
	}
}
