import Foundation

// MARK: - SetComponentRoyaltyConfig
public struct SetComponentRoyaltyConfig: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .setComponentRoyaltyConfig
	public func embed() -> Instruction {
		.setComponentRoyaltyConfig(self)
	}

	// MARK: Stored properties

	public let componentAddress: ComponentAddress
	public let royaltyConfig: Value_

	// MARK: Init

	public init(componentAddress: ComponentAddress, royaltyConfig: Value_) {
		self.componentAddress = componentAddress
		self.royaltyConfig = royaltyConfig
	}
}

public extension SetComponentRoyaltyConfig {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case componentAddress = "component_address"
		case royaltyConfig = "royalty_config"
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(componentAddress, forKey: .componentAddress)
		try container.encode(royaltyConfig, forKey: .royaltyConfig)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let componentAddress = try container.decode(ComponentAddress.self, forKey: .componentAddress)
		let royaltyConfig = try container.decode(Value_.self, forKey: .royaltyConfig)

		self.init(componentAddress: componentAddress, royaltyConfig: royaltyConfig)
	}
}
