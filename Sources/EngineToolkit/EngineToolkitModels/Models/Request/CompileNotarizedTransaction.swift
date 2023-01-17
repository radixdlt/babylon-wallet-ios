import Prelude

public typealias CompileNotarizedTransactionIntentRequest = NotarizedTransaction

// MARK: - CompileNotarizedTransactionIntentResponse
public struct CompileNotarizedTransactionIntentResponse: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let compiledNotarizedIntent: [UInt8]

	// MARK: Init

	public init(compiledNotarizedIntent: [UInt8]) {
		self.compiledNotarizedIntent = compiledNotarizedIntent
	}

	public init(compiledNotarizedIntentHex: String) throws {
		self.compiledNotarizedIntent = try [UInt8](hex: compiledNotarizedIntentHex)
	}
}

public extension CompileNotarizedTransactionIntentResponse {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case compiledNotarizedIntent = "compiled_notarized_intent"
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(compiledNotarizedIntent.hex(), forKey: .compiledNotarizedIntent)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(compiledNotarizedIntentHex: try container.decode(String.self, forKey: .compiledNotarizedIntent))
	}
}
