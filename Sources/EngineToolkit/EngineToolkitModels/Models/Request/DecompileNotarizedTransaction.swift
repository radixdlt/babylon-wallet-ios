// MARK: - DecompileNotarizedTransactionIntentRequest
public struct DecompileNotarizedTransactionIntentRequest: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let compiledNotarizedIntent: [UInt8]
	public let manifestInstructionsOutputFormat: ManifestInstructionsKind

	// MARK: Init

	public init(compiledNotarizedIntent: [UInt8], manifestInstructionsOutputFormat: ManifestInstructionsKind) {
		self.compiledNotarizedIntent = compiledNotarizedIntent
		self.manifestInstructionsOutputFormat = manifestInstructionsOutputFormat
	}

	public init(compiledNotarizedIntentHex: String, manifestInstructionsOutputFormat: ManifestInstructionsKind) throws {
		try self.init(
			compiledNotarizedIntent: [UInt8](hex: compiledNotarizedIntentHex),
			manifestInstructionsOutputFormat: manifestInstructionsOutputFormat
		)
	}
}

public extension DecompileNotarizedTransactionIntentRequest {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case compiledNotarizedIntent = "compiled_notarized_intent"
		case manifestInstructionsOutputFormat = "manifest_instructions_output_format"
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(compiledNotarizedIntent.hex(), forKey: .compiledNotarizedIntent)
		try container.encode(manifestInstructionsOutputFormat, forKey: .manifestInstructionsOutputFormat)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			compiledNotarizedIntentHex: container.decode(String.self, forKey: .compiledNotarizedIntent),
			manifestInstructionsOutputFormat: container.decode(ManifestInstructionsKind.self, forKey: .manifestInstructionsOutputFormat)
		)
	}
}

public typealias DecompileNotarizedTransactionIntentResponse = NotarizedTransaction
