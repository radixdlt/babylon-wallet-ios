import Foundation

// MARK: - ClearAuthZone
public struct ClearAuthZone: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .clearAuthZone
	public func embed() -> Instruction {
		.clearAuthZone(self)
	}

	public init() {}
}

public extension ClearAuthZone {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}
	}
}
