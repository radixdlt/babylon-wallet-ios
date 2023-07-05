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
	public let authorityRules: Map_

	// MARK: Init

	public init(code: Blob, schema: Bytes, royaltyConfig: Map_, metadata: Map_, authorityRules: Map_) {
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

		try container.encodeValue(code, forKey: .code)
		try container.encodeValue(schema, forKey: .schema)
		try container.encodeValue(metadata, forKey: .metadata)
		try container.encodeValue(authorityRules, forKey: .authorityRules)
		try container.encodeValue(royaltyConfig, forKey: .royaltyConfig)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			code: container.decodeValue(forKey: .code),
			schema: container.decodeValue(forKey: .schema),
			royaltyConfig: container.decodeValue(forKey: .royaltyConfig),
			metadata: container.decodeValue(forKey: .metadata),
			authorityRules: container.decodeValue(forKey: .authorityRules)
		)
	}
}
