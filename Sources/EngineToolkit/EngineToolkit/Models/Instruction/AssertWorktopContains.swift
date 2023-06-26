import Foundation

// MARK: - AssertWorktopContains
public struct AssertWorktopContains: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .assertWorktopContains
	public func embed() -> Instruction {
		.assertWorktopContains(self)
	}

	// MARK: Stored properties
	public let amount: Decimal_
	public let resourceAddress: ResourceAddress

	// MARK: Init

	// Using same order of args as Scrypto: AMOUNT, ADDRESS
	public init(
		amount: Decimal_,
		resourceAddress: ResourceAddress
	) {
		self.amount = amount
		self.resourceAddress = resourceAddress
	}
}

extension AssertWorktopContains {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case amount
		case resourceAddress = "resource_address"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encodeValue(resourceAddress, forKey: .resourceAddress)
		try container.encodeValue(amount, forKey: .amount)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			amount: container.decodeValue(forKey: .amount),
			resourceAddress: container.decodeValue(forKey: .resourceAddress)
		)
	}
}
