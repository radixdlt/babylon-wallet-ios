// MARK: - DecompileSignedTransactionIntentRequest
public struct DecompileSignedTransactionIntentRequest: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let compiledSignedIntent: [UInt8]
	public let instructionsOutputKind: ManifestInstructionsKind

	// MARK: Init

	public init(compiledSignedIntent: [UInt8], instructionsOutputKind: ManifestInstructionsKind) {
		self.compiledSignedIntent = compiledSignedIntent
		self.instructionsOutputKind = instructionsOutputKind
	}

	public init(compiledSignedIntentHex: String, instructionsOutputKind: ManifestInstructionsKind) throws {
		try self.init(compiledSignedIntent: [UInt8](hex: compiledSignedIntentHex), instructionsOutputKind: instructionsOutputKind)
	}
}

extension DecompileSignedTransactionIntentRequest {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case compiledSignedIntent = "compiled_signed_intent"
		case instructionsOutputKind = "instructions_output_kind"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(compiledSignedIntent.hex(), forKey: .compiledSignedIntent)
		try container.encode(instructionsOutputKind, forKey: .instructionsOutputKind)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			compiledSignedIntentHex: container.decode(String.self, forKey: .compiledSignedIntent),
			instructionsOutputKind: container.decode(ManifestInstructionsKind.self, forKey: .instructionsOutputKind)
		)
	}
}

public typealias DecompileSignedTransactionIntentResponse = SignedTransactionIntent
