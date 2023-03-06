import Prelude

// MARK: - FactorSource.Storage
public extension FactorSource {
	enum Storage: Sendable, Hashable, Codable {
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
		case discriminator, properties
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(Discriminator.self, forKey: .discriminator)
		switch discriminator {
		case .securityQuestions:
			self = try .forSecurityQuestions(container.decode(SecurityQuestionsStorage.self, forKey: .properties))
		case .device:
			self = try .forDevice(container.decode(DeviceStorage.self, forKey: .properties))
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(discriminator, forKey: .discriminator)

		switch self {
		case let .forSecurityQuestions(properties):
			try container.encode(properties, forKey: .properties)
		case let .forDevice(properties):
			try container.encode(properties, forKey: .properties)
		}
	}
}
