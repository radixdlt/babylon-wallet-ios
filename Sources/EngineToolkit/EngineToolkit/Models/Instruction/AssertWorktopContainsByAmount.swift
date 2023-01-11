import Foundation

// MARK: - AssertWorktopContainsByAmount
public struct AssertWorktopContainsByAmount: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .assertWorktopContainsByAmount
	public func embed() -> Instruction {
		.assertWorktopContainsByAmount(self)
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

public extension AssertWorktopContainsByAmount {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case amount
		case resourceAddress = "resource_address"
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encode(amount, forKey: .amount)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let resourceAddress: ResourceAddress = try container.decode(ResourceAddress.self, forKey: .resourceAddress)
		let amount: Decimal_ = try container.decode(Decimal_.self, forKey: .amount)

		self.init(
			amount: amount,
			resourceAddress: resourceAddress
		)
	}
}
