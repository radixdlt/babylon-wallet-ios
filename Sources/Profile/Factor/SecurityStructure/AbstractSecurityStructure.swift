import Prelude

// MARK: - AbstractSecurityStructure
public struct AbstractSecurityStructure<AbstractFactor>:
	Sendable, Hashable, Codable
	where AbstractFactor: FactorOfTierProtocol & Sendable & Hashable & Codable
{
	public typealias Role = RoleOfTier<AbstractFactor>
	public var primaryRole: Role
	public var recoveryRole: Role
	public var confirmationRole: Role

	public var numberOfDaysUntilAutoConfirmation: RecoveryAutoConfirmDelayInDays

	public init(
		numberOfDaysUntilAutoConfirmation: RecoveryAutoConfirmDelayInDays,
		primaryRole: Role,
		recoveryRole: Role,
		confirmationRole: Role
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
