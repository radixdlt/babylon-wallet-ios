import Foundation

// MARK: - CreateAccessController
public struct CreateAccessController: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createAccessController
	public func embed() -> Instruction {
		.createAccessController(self)
	}

	// MARK: Stored properties

	public let controlledAsset: Bucket
	public let ruleSet: Tuple
	public let timedRecoveryDelayInMinutes: ManifestASTValue

	// MARK: Init

	public init(
		controlledAsset: Bucket,
		ruleSet: Tuple,
		timedRecoveryDelayInMinutes: ManifestASTValue
	) {
		self.controlledAsset = controlledAsset
		self.ruleSet = ruleSet
		self.timedRecoveryDelayInMinutes = timedRecoveryDelayInMinutes
	}
}

extension CreateAccessController {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case controlledAsset = "controlled_asset"
		case ruleSet = "rule_set"
		case timedRecoveryDelayInMinutes = "timed_recovery_delay_in_minutes"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encodeValue(controlledAsset, forKey: .controlledAsset)
		try container.encodeValue(ruleSet, forKey: .ruleSet)
		try container.encode(timedRecoveryDelayInMinutes, forKey: .timedRecoveryDelayInMinutes)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			controlledAsset: container.decodeValue(forKey: .controlledAsset),
			ruleSet: container.decodeValue(forKey: .ruleSet),
			timedRecoveryDelayInMinutes: container.decode(ManifestASTValue.self, forKey: .timedRecoveryDelayInMinutes)
		)
	}
}
