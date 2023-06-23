// MARK: - StaticallyValidateTransactionRequest

public struct StaticallyValidateTransactionRequest: Codable, Equatable {
	public struct Config: Codable, Equatable {
		public let maxCostUnitLimit: String
		public let maxEpochRange: String
		public let maxNotarizedPayloadSize: String
		public let maxTipPercentage: String
		public let minCostUnitLimit: String
		public let minTipPercentage: String
		public let networkId: String

		private enum CodingKeys: String, CodingKey {
			case maxCostUnitLimit = "max_cost_unit_limit"
			case maxEpochRange = "max_epoch_range"
			case maxNotarizedPayloadSize = "max_notarized_payload_size"
			case maxTipPercentage = "max_tip_percentage"
			case minCostUnitLimit = "min_cost_unit_limit"
			case minTipPercentage = "min_tip_percentage"
			case networkId = "network_id"
		}

		public init(
			maxCostUnitLimit: String,
			maxEpochRange: String,
			maxNotarizedPayloadSize: String,
			maxTipPercentage: String,
			minCostUnitLimit: String,
			minTipPercentage: String,
			networkId: String
		) {
			self.maxCostUnitLimit = maxCostUnitLimit
			self.maxEpochRange = maxEpochRange
			self.maxNotarizedPayloadSize = maxNotarizedPayloadSize
			self.maxTipPercentage = maxTipPercentage
			self.minCostUnitLimit = minCostUnitLimit
			self.minTipPercentage = minTipPercentage
			self.networkId = networkId
		}
	}

	public let compiledNotarizedIntent: String
	public let validationConfig: Config

	public init(compiledNotarizedIntent: String, validationConfig: Config) {
		self.compiledNotarizedIntent = compiledNotarizedIntent
		self.validationConfig = validationConfig
	}

	private enum CodingKeys: String, CodingKey {
		case compiledNotarizedIntent = "compiled_notarized_intent"
		case validationConfig = "validation_config"
	}
}

// MARK: - StaticallyValidateTransactionResponse
public enum StaticallyValidateTransactionResponse: Codable, Equatable {
	case valid
	case invalid(String)

	private enum CodingKeys: String, CodingKey {
		case validity
		case error
	}

	enum Validity: String, Codable {
		case valid = "Valid"
		case invalid = "Invalid"
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let validity: Validity = try container.decode(forKey: .validity)

		switch validity {
		case .valid:
			self = .valid
		case .invalid:
			let error: String = try container.decode(forKey: .error)
			self = .invalid(error)
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case .valid:
			try container.encode(Validity.valid, forKey: .validity)
		case let .invalid(error):
			try container.encode(Validity.invalid, forKey: .validity)
			try container.encode(error, forKey: .error)
		}
	}
}
