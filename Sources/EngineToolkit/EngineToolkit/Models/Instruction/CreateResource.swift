import Foundation

// MARK: - CreateResource
public struct CreateResource: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createResource
	public func embed() -> Instruction {
		.createResource(self)
	}

	// MARK: Stored properties
	public let resourceType: Value_
	public let metadata: Array_
	public let accessRules: Array_
	public let mintParams: Value_

	// MARK: Init

	public init(resourceType: Value_, metadata: Array_, accessRules: Array_, mintParams: Value_) {
		self.resourceType = resourceType
		self.metadata = metadata
		self.accessRules = accessRules
		self.mintParams = mintParams
	}
}

public extension CreateResource {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case resourceType = "resource_type"
		case metadata
		case accessRules = "access_rules"
		case mintParams = "mint_params"
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(resourceType, forKey: .resourceType)
		try container.encode(metadata, forKey: .metadata)
		try container.encode(accessRules, forKey: .accessRules)
		try container.encode(mintParams, forKey: .mintParams)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let resourceType = try container.decode(Value_.self, forKey: .resourceType)
		let metadata = try container.decode(Array_.self, forKey: .metadata)
		let accessRules = try container.decode(Array_.self, forKey: .accessRules)
		let mintParamsValue = try container.decode(Value_.self, forKey: .mintParams)

		self.init(
			resourceType: resourceType,
			metadata: metadata,
			accessRules: accessRules,
			mintParams: mintParamsValue
		)
	}
}
