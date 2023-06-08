import Foundation

// MARK: - AssertAccessRule
public struct AssertAccessRule: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .assertAccessRule
	public func embed() -> Instruction {
		.assertAccessRule(self)
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

extension AssertAccessRule {
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

		let accessRule = try container.decode(Enum.self, forKey: .accessRule)

		self.init(
			accessRule: accessRule
		)
	}
}
