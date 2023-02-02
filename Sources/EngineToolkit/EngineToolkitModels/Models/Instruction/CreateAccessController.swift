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
	public let primaryRole: Enum
	public let recoveryRole: Enum
	public let confirmationRole: Enum
	public let timedRecoveryDelayInMinutes: Value_

	// MARK: Init

	public init(
		controlledAsset: Bucket,
		primaryRole: Enum,
		recoveryRole: Enum,
		confirmationRole: Enum,
		timedRecoveryDelayInMinutes: Value_
	) {
		self.controlledAsset = controlledAsset
		self.primaryRole = primaryRole
		self.recoveryRole = recoveryRole
		self.confirmationRole = confirmationRole
		self.timedRecoveryDelayInMinutes = timedRecoveryDelayInMinutes
	}
}

public extension CreateAccessController {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case controlledAsset = "controlled_asset"
		case primaryRole = "primary_role"
		case recoveryRole = "recovery_role"
		case confirmationRole = "confirmation_role"
		case timedRecoveryDelayInMinutes = "timed_recovery_delay_in_minutes"
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(controlledAsset, forKey: .controlledAsset)
		try container.encode(primaryRole, forKey: .primaryRole)
		try container.encode(recoveryRole, forKey: .recoveryRole)
		try container.encode(confirmationRole, forKey: .confirmationRole)
		try container.encode(timedRecoveryDelayInMinutes, forKey: .timedRecoveryDelayInMinutes)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let controlledAsset = try container.decode(Bucket.self, forKey: .controlledAsset)
		let primaryRole = try container.decode(Enum.self, forKey: .primaryRole)
		let recoveryRole = try container.decode(Enum.self, forKey: .recoveryRole)
		let confirmationRole = try container.decode(Enum.self, forKey: .confirmationRole)
		let timedRecoveryDelayInMinutes = try container.decode(Value_.self, forKey: .timedRecoveryDelayInMinutes).self

		self.init(
			controlledAsset: controlledAsset,
			primaryRole: primaryRole,
			recoveryRole: recoveryRole,
			confirmationRole: confirmationRole,
			timedRecoveryDelayInMinutes: timedRecoveryDelayInMinutes
		)
	}
}
