import Foundation

// MARK: - PublishPackage
public struct PublishPackage: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .publishPackage
	public func embed() -> Instruction {
		.publishPackage(self)
	}

	// MARK: Stored properties

	public let code: Blob
	public let schema: Blob
	public let royaltyConfig: Map_
	public let metadata: Map_

	// MARK: Init

	public init(code: Blob, schema: Blob, royaltyConfig: Map_, metadata: Map_) {
		self.code = code
		self.schema = schema
		self.royaltyConfig = royaltyConfig
		self.metadata = metadata
	}
}

extension PublishPackage {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case royaltyConfig = "royalty_config"
		case metadata
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
			schema: container.decode(Blob.self, forKey: .schema),
			royaltyConfig: container.decode(Map_.self, forKey: .royaltyConfig),
			metadata: container.decode(Map_.self, forKey: .metadata)
		)
	}
}
