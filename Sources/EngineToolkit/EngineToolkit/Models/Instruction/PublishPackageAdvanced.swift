import Foundation

// MARK: - PublishPackageAdvanced
public struct PublishPackageAdvanced: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .publishPackageAdvanced
	public func embed() -> Instruction {
		.publishPackageAdvanced(self)
	}

	// MARK: Stored properties

	public let code: Blob
	public let schema: Bytes
	public let royaltyConfig: Map_
	public let metadata: Map_
	public let authorityRules: Tuple

	// MARK: Init

	public init(code: Blob, schema: Bytes, royaltyConfig: Map_, metadata: Map_, authorityRules: Tuple) {
		self.code = code
		self.schema = schema
		self.royaltyConfig = royaltyConfig
		self.metadata = metadata
		self.authorityRules = authorityRules
	}
}

extension PublishPackageAdvanced {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case royaltyConfig = "royalty_config"
		case metadata
		case authorityRules = "authority_rules"
		case code
		case schema
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(code, forKey: .code)
		try container.encode(schema, forKey: .schema)
		try container.encode(metadata, forKey: .metadata)
		try container.encode(authorityRules, forKey: .authorityRules)
		try container.encode(royaltyConfig, forKey: .royaltyConfig)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			code: container.decode(Blob.self, forKey: .code),
			schema: container.decode(Bytes.self, forKey: .schema),
			royaltyConfig: container.decode(Map_.self, forKey: .royaltyConfig),
			metadata: container.decode(Map_.self, forKey: .metadata),
			authorityRules: container.decode(Tuple.self, forKey: .authorityRules)
		)
	}
}
