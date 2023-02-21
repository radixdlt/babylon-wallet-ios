// MARK: - DecompileUnknownTransactionIntentRequest
public struct DecompileUnknownTransactionIntentRequest: Sendable, Codable, Hashable {
	// MARK: Stored properties

	public let compiledUnknownIntent: [UInt8]
	public let instructionsOutputKind: ManifestInstructionsKind

	// MARK: Init

	public init(compiledUnknownIntent: [UInt8], instructionsOutputKind: ManifestInstructionsKind) {
		self.compiledUnknownIntent = compiledUnknownIntent
		self.instructionsOutputKind = instructionsOutputKind
	}

	public init(compiledUnknownIntentHex: String, instructionsOutputKind: ManifestInstructionsKind) throws {
		try self.init(
			compiledUnknownIntent: [UInt8](hex: compiledUnknownIntentHex),
			instructionsOutputKind: instructionsOutputKind
		)
	}
}

extension DecompileUnknownTransactionIntentRequest {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case compiledUnknownIntent = "compiled_unknown_intent"
		case instructionsOutputKind = "instructions_output_kind"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(compiledUnknownIntent.hex(), forKey: .compiledUnknownIntent)
		try container.encode(instructionsOutputKind, forKey: .instructionsOutputKind)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			compiledUnknownIntentHex: container.decode(String.self, forKey: .compiledUnknownIntent),
			instructionsOutputKind: container.decode(ManifestInstructionsKind.self, forKey: .instructionsOutputKind)
		)
	}
}

// MARK: - DecompileUnknownTransactionIntentResponse
public enum DecompileUnknownTransactionIntentResponse: Sendable, Codable, Hashable {
	// ==============
	// Enum Variants
	// ==============

	case transactionIntent(DecompileTransactionIntentResponse)
	case signedTransactionIntent(DecompileSignedTransactionIntentResponse)
	case notarizedTransactionIntent(DecompileNotarizedTransactionIntentResponse)
}

extension DecompileUnknownTransactionIntentResponse {
	private enum Kind: String, Codable {
		case transactionIntent = "TransactionIntent"
		case signedTransactionIntent = "SignedTransactionIntent"
		case notarizedTransactionIntent = "NotarizedTransactionIntent"
	}

	private enum CodingKeys: String, CodingKey {
		case type
		case value
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case let .transactionIntent(intent):
			try container.encode(Kind.transactionIntent, forKey: .type)
			try container.encode(intent, forKey: .value)
		case let .signedTransactionIntent(intent):
			try container.encode(Kind.signedTransactionIntent, forKey: .type)
			try container.encode(intent, forKey: .value)
		case let .notarizedTransactionIntent(intent):
			try container.encode(Kind.notarizedTransactionIntent, forKey: .type)
			try container.encode(intent, forKey: .value)
		}
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(Kind.self, forKey: .type)

		switch kind {
		case .transactionIntent:
			self = .transactionIntent(try container.decode(TransactionIntent.self, forKey: .value))
		case .signedTransactionIntent:
			self = .signedTransactionIntent(try container.decode(SignedTransactionIntent.self, forKey: .value))
		case .notarizedTransactionIntent:
			self = .notarizedTransactionIntent(try container.decode(NotarizedTransaction.self, forKey: .value))
		}
	}
}
