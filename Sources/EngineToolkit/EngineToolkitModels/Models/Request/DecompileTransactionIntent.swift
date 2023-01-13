// MARK: - DecompileTransactionIntentRequest
public struct DecompileTransactionIntentRequest: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let compiledIntent: [UInt8]
	public let manifestInstructionsOutputFormat: ManifestInstructionsKind

	// MARK: Init

	public init(compiledIntent: [UInt8], manifestInstructionsOutputFormat: ManifestInstructionsKind) {
		self.compiledIntent = compiledIntent
		self.manifestInstructionsOutputFormat = manifestInstructionsOutputFormat
	}

	public init(compiledIntentHex: String, manifestInstructionsOutputFormat: ManifestInstructionsKind) throws {
		try self.init(compiledIntent: [UInt8](hex: compiledIntentHex), manifestInstructionsOutputFormat: manifestInstructionsOutputFormat)
	}
}

public extension DecompileTransactionIntentRequest {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case compiledIntent = "compiled_intent"
		case manifestInstructionsOutputFormat = "manifest_instructions_output_format"
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(compiledIntent.hex(), forKey: .compiledIntent)
		try container.encode(manifestInstructionsOutputFormat, forKey: .manifestInstructionsOutputFormat)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			compiledIntentHex: container.decode(String.self, forKey: .compiledIntent),
			manifestInstructionsOutputFormat: container.decode(ManifestInstructionsKind.self, forKey: .manifestInstructionsOutputFormat)
		)
	}
}

public typealias DecompileTransactionIntentResponse = TransactionIntent
