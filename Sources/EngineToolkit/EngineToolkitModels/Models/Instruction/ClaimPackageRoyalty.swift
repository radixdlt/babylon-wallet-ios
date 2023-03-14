import Foundation

// MARK: - ClaimComponentRoyalty
public struct ClaimComponentRoyalty: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .claimComponentRoyalty
	public func embed() -> Instruction {
		.claimComponentRoyalty(self)
	}

	// MARK: Stored properties

	public let componentAddress: Address_

	// MARK: Init

	public init(componentAddress: ComponentAddress) {
		self.componentAddress = componentAddress.asGeneral
	}
}

extension ClaimComponentRoyalty {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case componentAddress = "component_address"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(componentAddress, forKey: .componentAddress)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			componentAddress: container.decode(Address_.self, forKey: .componentAddress).asSpecific()
		)
	}
}
