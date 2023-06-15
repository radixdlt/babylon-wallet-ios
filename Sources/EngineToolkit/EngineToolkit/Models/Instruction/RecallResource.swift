import Foundation

// MARK: - RecallResource
public struct RecallResource: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .recallResource
	public func embed() -> Instruction {
		.recallResource(self)
	}

	// MARK: Stored properties

	public let vault_id: Address
	public let amount: Decimal_

	// MARK: Init

	public init(vault_id: Address, amount: Decimal_) {
		self.vault_id = vault_id
		self.amount = amount
	}
}

extension RecallResource {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case vaultId = "vault_id"
		case amount
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encodeValue(vault_id, forKey: .vaultId)
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
			vault_id: container.decodeValue(forKey: .vaultId),
			amount: container.decodeValue(forKey: .amount)
		)
	}
}
