import Prelude

// MARK: - RoleOfTier
public struct RoleOfTier<AbstractFactor>: Sendable, Hashable, Codable where AbstractFactor: Sendable & Hashable & Codable {
	/// Factor instances which are used in combination with other instances, amounting to at
	/// least `threshold` many instances to perform some function with this role.
	public let thresholdFactorInstances: OrderedSet<AbstractFactor>

	/// How many threshold factor instances that must be used to perform some function with this role.
	public let threshold: UInt

	/// "sudo" factor instances, any **single** factor which can perform some function with this role,
	/// disregarding of `threshold`.
	public let superAdminFactorInstances: OrderedSet<AbstractFactor>
}

// MARK: - Profile.EntitySecurityStructure
extension Profile {
	public struct EntitySecurityStructure<AbstractFactor>: Sendable, Hashable, Codable where AbstractFactor: Sendable & Hashable & Codable {
		public typealias Role = RoleOfTier<AbstractFactor>
		public typealias PrimaryRole = Tagged<(Self, primary: ()), Role>
		public typealias RecoveryRole = Tagged<(Self, recovery: ()), Role>
		public typealias ConfirmationRole = Tagged<(Self, confirmation: ()), Role>
		public let primaryRole: PrimaryRole
		public let recoveryRole: RecoveryRole
		public let confirmationRole: ConfirmationRole
	}
}

// MARK: - AccessController
public struct AccessController: Sendable, Hashable, Codable {
	public struct Address: Sendable, Hashable, Codable {}

	/// On ledger component address
	public let address: Address

	/// Time factor, used e.g. by recovery role, as a countdown until recovery automaticall
	/// goes through.
	public let time: Duration

	public let securityStructure: Profile.EntitySecurityStructure<FactorInstance.ID>
}

// MARK: - Securified
public struct Securified: Sendable, Hashable, Codable {
	public let accessController: AccessController

	/// Single place for factor instances for this securified entity.
	private var transactionSigningFactorInstances: OrderedSet<FactorInstance>

	/// The factor instance which can be used for ROLA.
	public var authenticationSigning: HierarchicalDeterministicFactorInstance?
	/// The factor instance used to encrypt/decrypt messages
	public var messageEncryption: HierarchicalDeterministicFactorInstance?

	public var transactionSigningStructure: Profile.EntitySecurityStructure<FactorInstance> {
		func decorate(_ keyPath: KeyPath<Profile.EntitySecurityStructure<FactorInstance.ID>, Profile.EntitySecurityStructure<FactorInstance.ID>.Role>) -> Profile.EntitySecurityStructure<FactorInstance>.Role {
			fatalError()
		}
		return .init(
			primaryRole: .init(rawValue: decorate(\.primaryRole)),
			recoveryRole: .init(rawValue: decorate(\.recoveryRole)),
			confirmationRole: .init(decorate(\.confirmationRole))
		)
	}
}
