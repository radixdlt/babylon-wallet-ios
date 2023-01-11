// MARK: - DecompileSignedTransactionIntentRequest
public struct DecompileSignedTransactionIntentRequest: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let compiledSignedIntent: [UInt8]
	public let manifestInstructionsOutputFormat: ManifestInstructionsKind

	// MARK: Init

	public init(compiledSignedIntent: [UInt8], manifestInstructionsOutputFormat: ManifestInstructionsKind) {
		self.compiledSignedIntent = compiledSignedIntent
		self.manifestInstructionsOutputFormat = manifestInstructionsOutputFormat
	}

	public init(compiledSignedIntentHex: String, manifestInstructionsOutputFormat: ManifestInstructionsKind) throws {
		try self.init(compiledSignedIntent: [UInt8](hex: compiledSignedIntentHex), manifestInstructionsOutputFormat: manifestInstructionsOutputFormat)
	}
}

public extension DecompileSignedTransactionIntentRequest {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case compiledSignedIntent = "compiled_signed_intent"
		case manifestInstructionsOutputFormat = "manifest_instructions_output_format"
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(compiledSignedIntent.hex(), forKey: .compiledSignedIntent)
		try container.encode(manifestInstructionsOutputFormat, forKey: .manifestInstructionsOutputFormat)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			compiledSignedIntentHex: container.decode(String.self, forKey: .compiledSignedIntent),
			manifestInstructionsOutputFormat: try container.decode(ManifestInstructionsKind.self, forKey: .manifestInstructionsOutputFormat)
		)
	}
}

public typealias DecompileSignedTransactionIntentResponse = SignedTransactionIntent
