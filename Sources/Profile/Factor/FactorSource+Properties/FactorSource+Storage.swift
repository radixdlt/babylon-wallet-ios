import Prelude

// MARK: - FactorSource.Storage
public extension FactorSource {
	enum Storage: Sendable, Hashable, Codable {
		case forSecurityQuestions(SecurityQuestionsStorage)
	}
}

// MARK: Codable
extension FactorSource.Storage {
	private enum Discriminator: String, Codable {
		case securityQuestions
	}

	private var discriminator: Discriminator {
		switch self {
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
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Discriminator.securityQuestions, forKey: .discriminator)

		switch self {
		case let .forSecurityQuestions(properties):
			try container.encode(properties, forKey: .properties)
		}
	}
}
