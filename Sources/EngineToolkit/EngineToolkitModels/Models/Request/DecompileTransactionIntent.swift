// MARK: - DecompileTransactionIntentRequest
public struct DecompileTransactionIntentRequest: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let compiledIntent: [UInt8]
	public let instructionsOutputKind: ManifestInstructionsKind

	// MARK: Init

	public init(compiledIntent: [UInt8], instructionsOutputKind: ManifestInstructionsKind) {
		self.compiledIntent = compiledIntent
		self.instructionsOutputKind = instructionsOutputKind
	}

	public init(compiledIntentHex: String, instructionsOutputKind: ManifestInstructionsKind) throws {
		try self.init(compiledIntent: [UInt8](hex: compiledIntentHex), instructionsOutputKind: instructionsOutputKind)
	}
}

extension DecompileTransactionIntentRequest {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case compiledIntent = "compiled_intent"
		case instructionsOutputKind = "instructions_output_kind"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(compiledIntent.hex(), forKey: .compiledIntent)
		try container.encode(instructionsOutputKind, forKey: .instructionsOutputKind)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			compiledIntentHex: container.decode(String.self, forKey: .compiledIntent),
			instructionsOutputKind: container.decode(ManifestInstructionsKind.self, forKey: .instructionsOutputKind)
		)
	}
}

public typealias DecompileTransactionIntentResponse = TransactionIntent
