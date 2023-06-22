import Prelude

// MARK: - RoleOfTier
public struct RoleOfTier<Role, AbstractFactor>:
	Sendable, Hashable, Codable
	where
	Role: RoleProtocol,
	AbstractFactor: Sendable & Hashable & Codable
{
	public static var role: SecurityStructureRole { Role.role }

	/// Factors which are used in combination with other instances, amounting to at
	/// least `threshold` many instances to perform some function with this role.
	public var thresholdFactors: OrderedSet<AbstractFactor>

	/// How many threshold factors that must be used to perform some function with this role.
	public var threshold: UInt

	/// "sudo" factors, any **single** factor which can perform some function with this role,
	/// disregarding of `threshold`.
	public var superAdminFactors: OrderedSet<AbstractFactor>

	public init(
		thresholdFactors: OrderedSet<AbstractFactor>,
		threshold: UInt,
		superAdminFactors: OrderedSet<AbstractFactor>
	) {
		precondition(threshold <= thresholdFactors.count)
		self.thresholdFactors = thresholdFactors
		self.threshold = threshold
		self.superAdminFactors = superAdminFactors
	}

	public static func single(_ factor: AbstractFactor) -> Self {
		.init(thresholdFactors: [factor], threshold: 1, superAdminFactors: [])
	}
}

extension RoleOfTier where AbstractFactor == FactorSource {
	public static func single(_ factor: any FactorSourceProtocol) -> Self {
		Self.single(factor.embed())
	}
}

// MARK: - SecurityStructureRole
public enum SecurityStructureRole: Sendable, Hashable {
	case primary
	case recovery
	case confirmation
}

// MARK: - RoleProtocol
public protocol RoleProtocol {
	static var role: SecurityStructureRole { get }
}

// MARK: - PrimaryRoleTag
/// Tag for Primary role
public enum PrimaryRoleTag: RoleProtocol {
	public static let role: SecurityStructureRole = .primary
}

// MARK: - RecoveryRoleTag
/// Tag for Recovery role
public enum RecoveryRoleTag: RoleProtocol {
	public static let role: SecurityStructureRole = .recovery
}

// MARK: - ConfirmationRoleTag
/// Tag for confirmation role
public enum ConfirmationRoleTag: RoleProtocol {
	public static let role: SecurityStructureRole = .confirmation
}

public typealias PrimaryRole<AbstractFactor> = RoleOfTier<PrimaryRoleTag, AbstractFactor> where AbstractFactor: Sendable & Hashable & Codable
public typealias RecoveryRole<AbstractFactor> = RoleOfTier<RecoveryRoleTag, AbstractFactor> where AbstractFactor: Sendable & Hashable & Codable
public typealias ConfirmationRole<AbstractFactor> = RoleOfTier<ConfirmationRoleTag, AbstractFactor> where AbstractFactor: Sendable & Hashable & Codable

// MARK: - RecoveryAutoConfirmDelayInDaysTag
public enum RecoveryAutoConfirmDelayInDaysTag {}
public typealias RecoveryAutoConfirmDelayInDays = Tagged<RecoveryAutoConfirmDelayInDaysTag, UInt>

// MARK: - AbstractSecurityStructure
public struct AbstractSecurityStructure<AbstractFactor>:
	Sendable, Hashable, Codable
	where AbstractFactor: Sendable & Hashable & Codable
{
	public typealias Primary = PrimaryRole<AbstractFactor>
	public typealias Recovery = RecoveryRole<AbstractFactor>
	public typealias Confirmation = ConfirmationRole<AbstractFactor>
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

// MARK: - AbstractSecurityStructureConfiguration
public struct AbstractSecurityStructureConfiguration<AbstractFactor>:
	Sendable, Hashable, Codable, Identifiable
	where AbstractFactor: Sendable & Hashable & Codable
{
	public typealias ID = UUID
	public typealias Configuration = AbstractSecurityStructure<AbstractFactor>

	public let id: ID

	/// can be renamed
	public var label: NonEmptyString

	// Mutable so that we can update
	public var configuration: Configuration

	public let createdOn: Date

	// should update date when any changes occur
	public var lastUpdatedOn: Date

	public init(
		id: ID? = nil,
		label: NonEmptyString,
		configuration: Configuration,
		createdOn: Date? = nil,
		lastUpdatedOn: Date? = nil
	) {
		@Dependency(\.date) var date
		@Dependency(\.uuid) var uuid
		self.id = id ?? uuid()
		self.label = label
		self.createdOn = createdOn ?? date()
		self.lastUpdatedOn = lastUpdatedOn ?? date()
		self.configuration = configuration
	}
}

// MARK: - ProfileSnapshot.AppliedSecurityStructure
extension ProfileSnapshot {
	/// A version of `AppliedSecurityStructure` which only contains IDs of factor sources, suitable for storage in Profile Snapshot.
	public typealias AppliedSecurityStructure = AbstractSecurityStructure<FactorInstance.ID>
}

public typealias SecurityStructureConfigurationReference = AbstractSecurityStructureConfiguration<FactorSourceID>

extension SecurityStructureConfigurationReference.Configuration.Recovery {
	public static let defaultNumberOfDaysUntilAutoConfirmation: RecoveryAutoConfirmDelayInDays = .init(14)
}

public typealias SecurityStructureConfigurationDetailed = AbstractSecurityStructureConfiguration<FactorSource>

extension SecurityStructureConfigurationReference {
	public var isSimple: Bool {
		configuration.isSimple
	}
}

extension SecurityStructureConfigurationReference.Configuration {
	public var isSimple: Bool {
		primaryRole.hasSingleFactorSourceOf(kind: .device) &&
			recoveryRole.hasSingleFactorSourceOf(kind: .trustedContact) &&
			confirmationRole.hasSingleFactorSourceOf(kind: .securityQuestions)
	}
}

extension SecurityStructureConfigurationDetailed {
	public func asReference() -> SecurityStructureConfigurationReference {
		.init(
			id: id,
			label: label,
			configuration: configuration.asReference(),
			createdOn: createdOn,
			lastUpdatedOn: lastUpdatedOn
		)
	}

	public var isSimple: Bool {
		asReference().isSimple
	}
}

extension Profile {
	public func detailedSecurityStructureConfiguration(
		reference: SecurityStructureConfigurationReference
	) throws -> SecurityStructureConfigurationDetailed {
		try .init(
			id: reference.id,
			label: reference.label,
			configuration: detailedSecurityStructureConfiguration(referenceConfiguration: reference.configuration),
			createdOn: reference.createdOn,
			lastUpdatedOn: reference.lastUpdatedOn
		)
	}

	func detailedSecurityStructureConfiguration(
		referenceConfiguration reference: SecurityStructureConfigurationReference.Configuration
	) throws -> SecurityStructureConfigurationDetailed.Configuration {
		try .init(
			primaryRole: detailedSecurityStructureRole(referenceRole: reference.primaryRole),
			recoveryRole: detailedSecurityStructureRole(referenceRole: reference.recoveryRole),
			confirmationRole: detailedSecurityStructureRole(referenceRole: reference.confirmationRole)
		)
	}

	func detailedSecurityStructureRole<Role>(
		referenceRole reference: RoleOfTier<Role, FactorSourceID>
	) throws -> RoleOfTier<Role, FactorSource> {
		func lookup(id: FactorSourceID) throws -> FactorSource {
			guard let factorSource = factorSources.first(where: { $0.id == id }) else {
				throw FactorSourceWithIDNotFound()
			}
			return factorSource
		}

		return try .init(
			thresholdFactors: .init(validating: reference.thresholdFactors.map(lookup(id:))),
			threshold: reference.threshold,
			superAdminFactors: .init(validating: reference.superAdminFactors.map(lookup(id:)))
		)
	}
}

extension SecurityStructureConfigurationDetailed.Configuration {
	public func asReference() -> SecurityStructureConfigurationReference.Configuration {
		.init(
			primaryRole: primaryRole.asReference(),
			recoveryRole: recoveryRole.asReference(),
			confirmationRole: confirmationRole.asReference()
		)
	}

	public var isSimple: Bool {
		asReference().isSimple
	}
}

extension RoleOfTier {
	public var isSimple: Bool {
		superAdminFactors.isEmpty && threshold == 1 && thresholdFactors.count == 1
	}
}

extension RoleOfTier where AbstractFactor == FactorSourceID {
	public func hasSingleFactorSourceOf(kind expectedKind: FactorSourceKind) -> Bool {
		guard isSimple, let singleFactor = thresholdFactors.first else {
			return false
		}
		return singleFactor.kind == expectedKind
	}
}

extension RoleOfTier where AbstractFactor == FactorSource {
	public func asReference() -> RoleOfTier<Role, FactorSourceID> {
		try! .init(
			thresholdFactors: .init(validating: thresholdFactors.map(\.id)),
			threshold: threshold,
			superAdminFactors: .init(validating: superAdminFactors.map(\.id))
		)
	}

	public mutating func changeFactorSource(
		to newFactorSource: any FactorSourceProtocol
	) throws {
		try changeFactorSource(to: newFactorSource.embed())
	}

	public mutating func changeFactorSource(
		to newFactorSource: FactorSource
	) throws {
		guard isSimple else {
			throw UnableToChangeFactorSourceOfAdvancedSecurityStructureUsingSingleFactorSourceInput()
		}
		self.thresholdFactors = [newFactorSource]
	}
}

// MARK: - UnableToChangeFactorSourceOfAdvancedSecurityStructureUsingSingleFactorSourceInput
struct UnableToChangeFactorSourceOfAdvancedSecurityStructureUsingSingleFactorSourceInput: Swift.Error {}

public typealias AppliedSecurityStructure = AbstractSecurityStructure<FactorInstance>

// MARK: - AccessController
public struct AccessController: Sendable, Hashable, Codable {
	public struct Address: Sendable, Hashable, Codable {}

	/// On ledger component address
	public let address: Address

	/// Time factor, used e.g. by recovery role, as a countdown until recovery automaticall
	/// goes through.
	public let time: Duration

	public let securityStructure: ProfileSnapshot.AppliedSecurityStructure
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

	/// Maps from `FactorInstance.ID` to `FactorInstance`, which is what is useful for use through out the wallet.
	var transactionSigningStructure: AppliedSecurityStructure {
		func decorate<RoleTag>(
			tag: RoleTag.Type = RoleTag.self,
			_ keyPath: KeyPath<ProfileSnapshot.AppliedSecurityStructure, RoleOfTier<RoleTag, FactorInstance.ID>>
		) -> RoleOfTier<RoleTag, FactorInstance> {
			let roleWithfactorInstanceIDs = accessController.securityStructure[keyPath: keyPath]

			func lookup(id: FactorInstance.ID) -> FactorInstance {
				guard let factorInstance = transactionSigningFactorInstances.first(where: { $0.id == id }) else {
					let errorMessage = "Critical error, unable to find factor instance with ID: \(id), this should never happen."
					loggerGlobal.critical(.init(stringLiteral: errorMessage))
					fatalError(errorMessage)
				}
				return factorInstance
			}

			return .init(
				thresholdFactors: .init(uncheckedUniqueElements: roleWithfactorInstanceIDs.thresholdFactors.map(lookup(id:))),
				threshold: roleWithfactorInstanceIDs.threshold,
				superAdminFactors: .init(uncheckedUniqueElements: roleWithfactorInstanceIDs.superAdminFactors.map(lookup(id:)))
			)
		}

		return .init(
			primaryRole: decorate(\.primaryRole),
			recoveryRole: decorate(\.recoveryRole),
			confirmationRole: decorate(\.confirmationRole)
		)
	}
}

// MARK: - UnableToFindFactorInstanceWithID
struct UnableToFindFactorInstanceWithID: Swift.Error {
	let id: FactorInstance.ID
}
