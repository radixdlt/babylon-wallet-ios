import Foundation

// MARK: - CreateAccount
public struct CreateAccount: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createAccount
	public func embed() -> Instruction {
		.createAccount(self)
	}

	// MARK: Init

	public init() {}
}

extension CreateAccount {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}
	}
}
