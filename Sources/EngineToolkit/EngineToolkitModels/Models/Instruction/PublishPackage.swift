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
	public let abi: Blob
	public let royaltyConfig: Map_
	public let metadata: Map_
	public let accessRules: Enum

	// MARK: Init

	public init(code: Blob, abi: Blob, royaltyConfig: Map_, metadata: Map_, accessRules: Enum) {
		self.code = code
		self.abi = abi
		self.royaltyConfig = royaltyConfig
		self.metadata = metadata
		self.accessRules = accessRules
	}
}

public extension PublishPackage {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case royaltyConfig = "royalty_config"
		case metadata
		case accessRules = "access_rules"
		case code
		case abi
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(code, forKey: .code)
		try container.encode(abi, forKey: .abi)
		try container.encode(metadata, forKey: .metadata)
		try container.encode(accessRules, forKey: .accessRules)
		try container.encode(royaltyConfig, forKey: .royaltyConfig)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			code: container.decode(Blob.self, forKey: .code),
			abi: container.decode(Blob.self, forKey: .abi),
			royaltyConfig: container.decode(Map_.self, forKey: .royaltyConfig),
			metadata: container.decode(Map_.self, forKey: .metadata),
			accessRules: container.decode(Enum.self, forKey: .accessRules)
		)
	}
}
