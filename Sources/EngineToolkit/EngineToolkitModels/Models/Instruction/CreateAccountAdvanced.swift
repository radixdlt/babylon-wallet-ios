import Foundation

// MARK: - CreateAccountAdvanced
public struct CreateAccountAdvanced: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createAccountAdvanced
	public func embed() -> Instruction {
		.createAccountAdvanced(self)
	}

	// MARK: Stored properties

	public let config: Tuple

	// MARK: Init

	public init(
		config: Tuple
	) {
		self.config = config
	}
}

extension CreateAccountAdvanced {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case config
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(config, forKey: .config)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			config: container.decode(Tuple.self, forKey: .config)
		)
	}
}
