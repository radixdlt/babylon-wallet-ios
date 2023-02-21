import Foundation

// MARK: - AssertWorktopContains
public struct AssertWorktopContains: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .assertWorktopContains
	public func embed() -> Instruction {
		.assertWorktopContains(self)
	}

	// MARK: Stored properties
	public let resourceAddress: ResourceAddress

	// MARK: Init

	public init(resourceAddress: ResourceAddress) {
		self.resourceAddress = resourceAddress
	}
}

extension AssertWorktopContains {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case resourceAddress = "resource_address"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(resourceAddress, forKey: .resourceAddress)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let resourceAddress: ResourceAddress = try container.decode(ResourceAddress.self, forKey: .resourceAddress)

		self.init(resourceAddress: resourceAddress)
	}
}
