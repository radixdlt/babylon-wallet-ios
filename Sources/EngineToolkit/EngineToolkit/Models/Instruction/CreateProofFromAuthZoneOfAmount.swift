import Foundation

// MARK: - CreateProofFromAuthZoneOfAmount
public struct CreateProofFromAuthZoneOfAmount: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createProofFromAuthZoneOfAmount
	public func embed() -> Instruction {
		.createProofFromAuthZoneOfAmount(self)
	}

	// MARK: Stored properties
	public let resourceAddress: ResourceAddress
	public let amount: Decimal_
	public let intoProof: Proof

	// MARK: Init

	public init(
		resourceAddress: ResourceAddress,
		amount: Decimal_,
		intoProof: Proof
	) {
		self.resourceAddress = resourceAddress
		self.amount = amount
		self.intoProof = intoProof
	}
}

extension CreateProofFromAuthZoneOfAmount {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case amount
		case resourceAddress = "resource_address"
		case intoProof = "into_proof"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encodeValue(resourceAddress, forKey: .resourceAddress)
		try container.encodeValue(amount, forKey: .amount)
		try container.encodeValue(intoProof, forKey: .intoProof)
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
			amount: container.decodeValue(forKey: .amount),
			intoProof: container.decodeValue(forKey: .intoProof)
		)
	}
}
