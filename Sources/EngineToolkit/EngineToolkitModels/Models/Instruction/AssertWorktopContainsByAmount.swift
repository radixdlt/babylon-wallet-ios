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
	/// Temporary, will change to `Address`. This can actually only be either `ResourceAddress` or `Address_`.
	public let resourceAddress: Value_

	// MARK: Init

	// Using same order of args as Scrypto: AMOUNT, ADDRESS
	public init(
		amount: Decimal_,
		resourceAddress: ResourceAddress
	) {
		self.amount = amount
		self.resourceAddress = .resourceAddress(resourceAddress)
	}

	public init(
		amount: Decimal_,
		resourceAddress: Address_
	) {
		self.amount = amount
		self.resourceAddress = .address(resourceAddress)
	}
}

extension AssertWorktopContainsByAmount {
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

		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encode(amount, forKey: .amount)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		self.resourceAddress = try container.decode(Value_.self, forKey: .resourceAddress)
		self.amount = try container.decode(Decimal_.self, forKey: .amount)
	}
}
