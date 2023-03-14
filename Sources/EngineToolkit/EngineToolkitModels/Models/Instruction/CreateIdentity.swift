import Foundation

// MARK: - CreateIdentity
public struct CreateIdentity: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createIdentity
	public func embed() -> Instruction {
		.createIdentity(self)
	}

	// MARK: Stored properties

	public let accessRule: Enum

	// MARK: Init

	public init(
		accessRule: Enum
	) {
		self.accessRule = accessRule
	}
}

extension CreateIdentity {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case accessRule = "access_rule"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(accessRule, forKey: .accessRule)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			accessRule: container.decode(Enum.self, forKey: .accessRule)
		)
	}
}
