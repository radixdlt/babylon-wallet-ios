import Foundation

// MARK: - CreateValidator
public struct CreateValidator: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createValidator
	public func embed() -> Instruction {
		.createValidator(self)
	}

	// MARK: Stored properties

	public let key: Bytes

	// MARK: Init

	public init(key: Bytes) {
		self.key = key
	}
}

extension CreateValidator {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case key
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encodeValue(key, forKey: .key)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			key: container.decodeValue(forKey: .key)
		)
	}
}
