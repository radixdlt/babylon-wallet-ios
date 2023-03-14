import Foundation

// MARK: - CreateAccount
public struct CreateAccount: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createAccount
	public func embed() -> Instruction {
		.createAccount(self)
	}

	// MARK: Stored properties

	public let withdrawRule: Enum

	// MARK: Init

	public init(withdrawRule: Enum) {
		self.withdrawRule = withdrawRule
	}
}

extension CreateAccount {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case withdrawRule = "withdraw_rule"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(withdrawRule, forKey: .withdrawRule)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			withdrawRule: container.decode(Enum.self, forKey: .withdrawRule)
		)
	}
}
