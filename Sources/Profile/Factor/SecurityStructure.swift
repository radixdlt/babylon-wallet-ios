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

	public init(
		primaryRole: Primary,
		recoveryRole: Recovery,
		confirmationRole: Confirmation
	) {
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

extension ProfileSnapshot {
	public typealias SecurityStructureConfiguration = AbstractSecurityStructureConfiguration<FactorSourceID>

	/// A version of `AppliedSecurityStructure` which only contains IDs of factor sources, suitable for storage in Profile Snapshot.
	public typealias AppliedSecurityStructure = AbstractSecurityStructure<FactorInstance.ID>
}

public typealias SecurityStructureConfiguration = AbstractSecurityStructureConfiguration<FactorSource>

extension SecurityStructureConfiguration {
	public var isSimple: Bool {
		configuration.isSimple
	}
}

extension SecurityStructureConfiguration.Configuration {
	public var isSimple: Bool {
		primaryRole.hasSingleFactorSourceOf(kind: .device) &&
			recoveryRole.hasSingleFactorSourceOf(kind: .trustedContact) &&
			confirmationRole.hasSingleFactorSourceOf(kind: .securityQuestions)
	}
}

extension RoleOfTier {
	public var isSimple: Bool {
		superAdminFactors.isEmpty && threshold == 1 && thresholdFactors.count == 1
	}
}

extension RoleOfTier where AbstractFactor == FactorSource {
	public func hasSingleFactorSourceOf(kind expectedKind: FactorSourceKind) -> Bool {
		guard isSimple, let singleFactor = thresholdFactors.first else {
			return false
		}
		return singleFactor.kind == expectedKind
	}

	public mutating func changeFactorSource(to newFactorSource: any FactorSourceProtocol) throws {
		try changeFactorSource(to: newFactorSource.embed())
	}

	public mutating func changeFactorSource(to newFactorSource: FactorSource) throws {
		guard isSimple else {
			throw UnableToChangeFactorSourceOfAdvancedSecurityStructureUsingSingleFactorSourceInput()
		}
		self.thresholdFactors = [newFactorSource]
	}
}

// MARK: - UnableToChangeFactorSourceOfAdvancedSecurityStructureUsingSingleFactorSourceInput
struct UnableToChangeFactorSourceOfAdvancedSecurityStructureUsingSingleFactorSourceInput: Swift.Error {}

public typealias AppliedSecurityStructure = AbstractSecurityStructure<FactorInstance>

// MARK: - TemplateFactorSourceKindPlaceholder
public struct TemplateFactorSourceKindPlaceholder: Sendable, Hashable, Codable {
	/// The factor source kind we wanna use for some role.
	public let factorSourceKind: FactorSourceKind

	/// Only serves as a semi hacky workaround the fact that we use `OrderedSet` (and wanna keep it) in Role structure,
	/// but with a`SecurityStructureConfigurationTemplate` we wanna be able to express "use two `device` Factor Sources for primaryRole"
	/// the `placeholderID` make sure two can put two `device` in the same `OrderedSet` wrapped in `TemplateFactorSourceKindPlaceholder`.
	public let placeholderID: UUID

	public init(
		_ factorSourceKind: FactorSourceKind,
		placeholderID: UUID = .init()
	) {
		self.placeholderID = placeholderID
		self.factorSourceKind = factorSourceKind
	}
}

public typealias SecurityStructureConfigurationTemplate = AbstractSecurityStructureConfiguration<TemplateFactorSourceKindPlaceholder>

extension SecurityStructureConfigurationTemplate {
	public static let `default`: Self = .init(
		label: "Recommended security structure",
		configuration: .init(
			primaryRole: .single(.init(.device)),
			recoveryRole: .single(.init(.trustedContact)),
			confirmationRole: .single(.init(.securityQuestions))
		)
	)
}

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
