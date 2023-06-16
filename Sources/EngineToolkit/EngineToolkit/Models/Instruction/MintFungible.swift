import Foundation

// MARK: - MintFungible
public struct MintFungible: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .mintFungible
	public func embed() -> Instruction {
		.mintFungible(self)
	}

	// MARK: Stored properties
	public let resourceAddress: ResourceAddress
	public let amount: Decimal_

	// MARK: Init

	public init(
		resourceAddress: ResourceAddress,
		amount: Decimal_
	) {
		self.resourceAddress = resourceAddress
		self.amount = amount
	}
}

extension MintFungible {
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
			resourceAddress: container.decodeValue(forKey: .resourceAddress),
			amount: container.decodeValue(forKey: .amount)
		)
	}
}
