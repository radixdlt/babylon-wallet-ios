import Prelude

// MARK: - AbstractSecurityStructure
public struct AbstractSecurityStructure<AbstractFactor>:
	Sendable, Hashable, Codable
	where AbstractFactor: FactorOfTierProtocol & Sendable & Hashable & Codable
{
	public typealias Primary = RoleOfTier<PrimaryRoleTag, AbstractFactor>
	public typealias Recovery = RoleOfTier<RecoveryRoleTag, AbstractFactor>
	public typealias Confirmation = RoleOfTier<ConfirmationRoleTag, AbstractFactor>
	public var primaryRole: Primary
	public var recoveryRole: Recovery
	public var confirmationRole: Confirmation

	public var numberOfMinutesUntilAutoConfirmation: RecoveryAutoConfirmDelayInMinutes

	public init(
		numberOfMinutesUntilAutoConfirmation: RecoveryAutoConfirmDelayInMinutes,
		primaryRole: Primary,
		recoveryRole: Recovery,
		confirmationRole: Confirmation
	) {
		self.numberOfMinutesUntilAutoConfirmation = numberOfMinutesUntilAutoConfirmation
		self.primaryRole = primaryRole
		self.recoveryRole = recoveryRole
		self.confirmationRole = confirmationRole
	}
}

// MARK: - RecoveryAutoConfirmDelayInMinutesTag
public enum RecoveryAutoConfirmDelayInMinutesTag {}
public typealias RecoveryAutoConfirmDelayInMinutes = Tagged<RecoveryAutoConfirmDelayInMinutesTag, UInt64>
