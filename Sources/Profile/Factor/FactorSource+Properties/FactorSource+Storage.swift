import Prelude

// MARK: - FactorSource.Storage
extension FactorSource {
	public enum Storage: Sendable, Hashable, Codable {
		/// `device`
		case forDevice(DeviceStorage)
		/// `securityQuestions`
		case forSecurityQuestions(SecurityQuestionsStorage)
	}
}

extension FactorSource.Storage {
	public var forDevice: DeviceStorage? {
		guard case let .forDevice(storage) = self else {
			return nil
		}
		return storage
	}

	public var forSecurityQuestions: SecurityQuestionsStorage? {
		guard case let .forSecurityQuestions(storage) = self else {
			return nil
		}
		return storage
	}

	public func asDevice() throws -> DeviceStorage {
		guard let forDevice else {
			throw WasNotDeviceFactorSource()
		}
		return forDevice
	}
}

// MARK: - WasNotDeviceFactorSource
struct WasNotDeviceFactorSource: Swift.Error {}

extension FactorSource {
	public func deviceStorage() throws -> DeviceStorage {
		guard let storage else {
			throw WasNotDeviceFactorSource()
		}
		return try storage.asDevice()
	}
}

// MARK: Codable
extension FactorSource.Storage {
	private enum Discriminator: String, Codable {
		case securityQuestions
		case device
	}

	private var discriminator: Discriminator {
		switch self {
		case .forDevice: return .device
		case .forSecurityQuestions: return .securityQuestions
		}
	}

	private enum CodingKeys: String, CodingKey {
		case discriminator
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(Discriminator.self, forKey: .discriminator)
		switch discriminator {
		case .securityQuestions:
			self = try .forSecurityQuestions(SecurityQuestionsStorage(from: decoder))
		case .device:
			self = try .forDevice(DeviceStorage(from: decoder))
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(discriminator, forKey: .discriminator)
		switch self {
		case let .forSecurityQuestions(properties):
			try properties.encode(to: encoder)
		case let .forDevice(properties):
			try properties.encode(to: encoder)
		}
	}
}
