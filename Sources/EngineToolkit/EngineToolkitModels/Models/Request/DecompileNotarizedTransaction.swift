// MARK: - DecompileNotarizedTransactionIntentRequest
public struct DecompileNotarizedTransactionIntentRequest: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let compiledNotarizedIntent: [UInt8]
	public let instructionsOutputKind: ManifestInstructionsKind

	// MARK: Init

	public init(compiledNotarizedIntent: [UInt8], instructionsOutputKind: ManifestInstructionsKind) {
		self.compiledNotarizedIntent = compiledNotarizedIntent
		self.instructionsOutputKind = instructionsOutputKind
	}

	public init(compiledNotarizedIntentHex: String, instructionsOutputKind: ManifestInstructionsKind) throws {
		try self.init(
			compiledNotarizedIntent: [UInt8](hex: compiledNotarizedIntentHex),
			instructionsOutputKind: instructionsOutputKind
		)
	}
}

public extension DecompileNotarizedTransactionIntentRequest {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case compiledNotarizedIntent = "compiled_notarized_intent"
		case instructionsOutputKind = "instructions_output_kind"
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(compiledNotarizedIntent.hex(), forKey: .compiledNotarizedIntent)
		try container.encode(instructionsOutputKind, forKey: .instructionsOutputKind)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			compiledNotarizedIntentHex: container.decode(String.self, forKey: .compiledNotarizedIntent),
			instructionsOutputKind: container.decode(ManifestInstructionsKind.self, forKey: .instructionsOutputKind)
		)
	}
}

public typealias DecompileNotarizedTransactionIntentResponse = NotarizedTransaction
