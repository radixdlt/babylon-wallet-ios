import Prelude

// MARK: - FactorSource.Storage
extension FactorSource {
	public enum Storage: Sendable, Hashable, Codable {
		/// EntityCreating
		case entityCreating(FactorSource.Storage.EntityCreating)

		/// `securityQuestions`
		case securityQuestions(SecurityQuestionsStorage)
	}
}

extension FactorSource.Storage {
	public var entityCreating: FactorSource.Storage.EntityCreating? {
		guard case let .entityCreating(storage) = self else {
			return nil
		}
		return storage
	}

	public var securityQuestions: SecurityQuestionsStorage? {
		guard case let .securityQuestions(storage) = self else {
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
		case securityQuestions
		case entityCreating
	}

	private var discriminator: Discriminator {
		switch self {
		case .entityCreating: return .entityCreating
		case .securityQuestions: return .securityQuestions
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
			self = try .securityQuestions(SecurityQuestionsStorage(from: decoder))
		case .entityCreating:
			self = try .entityCreating(FactorSource.Storage.EntityCreating(from: decoder))
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(discriminator, forKey: .discriminator)
		switch self {
		case let .securityQuestions(properties):
			try properties.encode(to: encoder)
		case let .entityCreating(properties):
			try properties.encode(to: encoder)
		}
	}
}
