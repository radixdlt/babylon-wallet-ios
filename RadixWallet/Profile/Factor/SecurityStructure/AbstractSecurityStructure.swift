import EngineToolkit

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

	public var numberOfDaysUntilAutoConfirmation: RecoveryAutoConfirmDelayInDays

	public init(
		numberOfDaysUntilAutoConfirmation: RecoveryAutoConfirmDelayInDays,
		primaryRole: Primary,
		recoveryRole: Recovery,
		confirmationRole: Confirmation
	) {
		self.numberOfDaysUntilAutoConfirmation = numberOfDaysUntilAutoConfirmation
		self.primaryRole = primaryRole
		self.recoveryRole = recoveryRole
		self.confirmationRole = confirmationRole
	}
}

// MARK: - RecoveryAutoConfirmDelayInDaysTag
public enum RecoveryAutoConfirmDelayInDaysTag {}
public typealias RecoveryAutoConfirmDelayInDays = Tagged<RecoveryAutoConfirmDelayInDaysTag, UInt>
