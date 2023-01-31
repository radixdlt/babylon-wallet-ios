import Foundation

// MARK: - CreateValidator
public struct CreateValidator: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createValidator
	public func embed() -> Instruction {
		.createValidator(self)
	}

	// MARK: Stored properties

	public let key: EcdsaSecp256k1PublicKey

	// MARK: Init

	public init(
		key: EcdsaSecp256k1PublicKey
	) {
		self.key = key
	}
}

public extension CreateValidator {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case key
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(key, forKey: .key)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let key = try container.decode(EcdsaSecp256k1PublicKey.self, forKey: .key)

		self.init(
			key: key
		)
	}
}
