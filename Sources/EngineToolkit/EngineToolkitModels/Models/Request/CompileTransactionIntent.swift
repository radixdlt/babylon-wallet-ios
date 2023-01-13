public typealias CompileTransactionIntentRequest = TransactionIntent

// MARK: - CompileTransactionIntentResponse
public struct CompileTransactionIntentResponse: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let compiledIntent: [UInt8]

	// MARK: Init

	public init(compiledIntent: [UInt8]) {
		self.compiledIntent = compiledIntent
	}

	public init(compiledIntentHex: String) throws {
		self.compiledIntent = try [UInt8](hex: compiledIntentHex)
	}
}

public extension CompileTransactionIntentResponse {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case compiledIntent = "compiled_intent"
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(compiledIntent.hex(), forKey: .compiledIntent)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(compiledIntentHex: container.decode(String.self, forKey: .compiledIntent))
	}
}
