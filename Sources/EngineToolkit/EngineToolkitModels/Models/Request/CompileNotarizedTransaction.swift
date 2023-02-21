import Prelude

public typealias CompileNotarizedTransactionIntentRequest = NotarizedTransaction

// MARK: - CompileNotarizedTransactionIntentResponse
public struct CompileNotarizedTransactionIntentResponse: Sendable, Codable, Hashable {
	// MARK: Stored properties

	public let compiledIntent: [UInt8]

	// MARK: Init

	public init(compiledIntent: [UInt8]) {
		self.compiledIntent = compiledIntent
	}

	public init(compiledIntentHex: String) throws {
		self.compiledIntent = try .init(hex: compiledIntentHex)
	}
}

extension CompileNotarizedTransactionIntentResponse {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case compiledIntent = "compiled_intent"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(compiledIntent.hex(), forKey: .compiledIntent)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(compiledIntentHex: try container.decode(String.self, forKey: .compiledIntent))
	}
}
