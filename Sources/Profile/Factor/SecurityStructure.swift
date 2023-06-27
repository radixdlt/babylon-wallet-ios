import Prelude

// MARK: - SupportedUsageForRole
public enum SupportedUsageForRole: Sendable, Hashable {
	/// Either alone or combined with other
	case aloneOrWhenCombinedWithOther

	/// Not alone, only together with another FactorSourceKind
	case onlyWhenCombinedWithOther
}

extension FactorSourceKind {
	public var supportedUsageForPrimaryRole: SupportedUsageForRole? {
		switch self {
		case .device:
			return .aloneOrWhenCombinedWithOther

		case .ledgerHQHardwareWallet:
			return .aloneOrWhenCombinedWithOther

		case .offDeviceMnemonic:
			return .aloneOrWhenCombinedWithOther

		case .trustedContact:
			return nil

		case .securityQuestions:
			return .onlyWhenCombinedWithOther
		}
	}

	public var supportedUsageForRecoveryRole: SupportedUsageForRole? {
		switch self {
		case .device:
			// If a user has lost her phone, how can she use it to perform recovery...she cant!
			return nil

		case .ledgerHQHardwareWallet:
			return .aloneOrWhenCombinedWithOther

		case .offDeviceMnemonic:
			return .aloneOrWhenCombinedWithOther

		case .trustedContact:
			return .aloneOrWhenCombinedWithOther

		case .securityQuestions:
			return .onlyWhenCombinedWithOther
		}
	}

	public var supportedUsageForConfirmationRole: SupportedUsageForRole? {
		switch self {
		case .device:
			return .aloneOrWhenCombinedWithOther

		case .ledgerHQHardwareWallet:
			return .aloneOrWhenCombinedWithOther

		case .offDeviceMnemonic:
			return .aloneOrWhenCombinedWithOther

		case .trustedContact:
			return nil

		case .securityQuestions:
			return .aloneOrWhenCombinedWithOther
		}
	}

	public func supports(
		role: SecurityStructureRole
	) -> Bool {
		supportedUsage(for: role) != nil
	}

	public func supportedUsage(
		for role: SecurityStructureRole
	) -> SupportedUsageForRole? {
		switch role {
		case .primary:
			return supportedUsageForPrimaryRole

		case .recovery:
			return supportedUsageForRecoveryRole

		case .confirmation:
			return supportedUsageForConfirmationRole
		}
	}
}

// MARK: - RoleOfTier
public struct RoleOfTier<AbstractFactor>:
	Sendable, Hashable, Codable
	where
	AbstractFactor: FactorOfTierProtocol & Sendable & Hashable & Codable
{
	/// Factors which are used in combination with other instances, amounting to at
	/// least `threshold` many instances to perform some function with this role.
	public var thresholdFactors: OrderedSet<AbstractFactor>

	/// How many threshold factors that must be used to perform some function with this role.
	public var threshold: UInt

	/// "sudo" factors, any **single** factor which can perform some function with this role,
	/// disregarding of `threshold`.
	public var superAdminFactors: OrderedSet<AbstractFactor>

	public init(
		role: SecurityStructureRole,
		thresholdFactors: OrderedSet<AbstractFactor>,
		threshold: UInt,
		superAdminFactors: OrderedSet<AbstractFactor>
	) throws {
		guard threshold <= thresholdFactors.count else {
			throw RoleOfTierError.thresholdMustBeLessThanOrEqualToLengthOfThresholdFactors
		}

		if
			let first = thresholdFactors.first,
			thresholdFactors.count == 1,
			first.factorSourceKind.supportedUsage(for: role) == .onlyWhenCombinedWithOther
		{
			throw RoleOfTierError.thresholdFactorContainsSingleFactorNotAllowdToBeSingle
		}

		guard thresholdFactors.allSatisfy({ $0.factorSourceKind.supports(role: role) }) else {
			throw RoleOfTierError.thresholdFactorsSupportsUnsupportedFactorSourceKindForRole
		}

		guard !superAdminFactors.contains(where: { $0.factorSourceKind.supportedUsage(for: role) == .onlyWhenCombinedWithOther }) else {
			throw RoleOfTierError.adminFactorContainsFactorNotAllowdToBeSingle
		}

		guard superAdminFactors.allSatisfy({ $0.factorSourceKind.supports(role: role) }) else {
			throw RoleOfTierError.adminFactorContainsUnsupportedFactors
		}

		self.thresholdFactors = thresholdFactors
		self.threshold = threshold
		self.superAdminFactors = superAdminFactors
	}

	internal init(
		uncheckedThresholdFactors thresholdFactors: OrderedSet<AbstractFactor>,
		superAdminFactors: OrderedSet<AbstractFactor>,
		threshold: UInt
	) {
		precondition(threshold <= thresholdFactors.count)
		self.thresholdFactors = thresholdFactors
		self.superAdminFactors = superAdminFactors
		self.threshold = threshold
	}

	public static func single(
		_ factor: AbstractFactor,
		for role: SecurityStructureRole
	) -> Self {
		self.init(uncheckedThresholdFactors: [factor], superAdminFactors: [], threshold: 1)
	}
}

// MARK: - RoleOfTierError
public enum RoleOfTierError: Swift.Error {
	case thresholdMustBeLessThanOrEqualToLengthOfThresholdFactors
	case thresholdFactorsSupportsUnsupportedFactorSourceKindForRole
	case adminFactorsSupportsUnsupportedFactorSourceKindForRole
	case thresholdFactorContainsSingleFactorNotAllowdToBeSingle
	case adminFactorContainsFactorNotAllowdToBeSingle
	case adminFactorContainsUnsupportedFactors
}

extension RoleOfTier where AbstractFactor == FactorSource {
	public static func single(
		_ factor: any FactorSourceProtocol,
		for role: SecurityStructureRole
	) -> Self {
		Self.single(factor.embed(), for: role)
	}
}

// MARK: - SecurityStructureRole
public enum SecurityStructureRole: Sendable, Hashable, Codable {
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

// MARK: - RecoveryAutoConfirmDelayInDaysTag
public enum RecoveryAutoConfirmDelayInDaysTag {}
public typealias RecoveryAutoConfirmDelayInDays = Tagged<RecoveryAutoConfirmDelayInDaysTag, UInt>

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

// MARK: - SecurityStructureMetadata
public struct SecurityStructureMetadata: Sendable, Hashable, Codable, Identifiable {
	public typealias ID = UUID
	public let id: ID

	/// can be renamed
	public var label: String

	public let createdOn: Date

	// should update date when any changes occur
	public var lastUpdatedOn: Date

	public init(
		id: ID? = nil,
		label: String = "",
		createdOn: Date? = nil,
		lastUpdatedOn: Date? = nil
	) {
		@Dependency(\.date) var date
		@Dependency(\.uuid) var uuid
		self.id = id ?? uuid()
		self.label = label
		self.createdOn = createdOn ?? date()
		self.lastUpdatedOn = lastUpdatedOn ?? date()
	}
}

// MARK: - AbstractSecurityStructureConfiguration
public struct AbstractSecurityStructureConfiguration<AbstractFactor>:
	Sendable, Hashable, Codable, Identifiable
	where AbstractFactor: FactorOfTierProtocol & Sendable & Hashable & Codable
{
	public typealias Configuration = AbstractSecurityStructure<AbstractFactor>
	// Mutable so that we can update factor structure
	public var configuration: Configuration

	// Mutable so we can rename and update date
	public var metadata: SecurityStructureMetadata

	public init(
		metadata: SecurityStructureMetadata,
		configuration: Configuration
	) {
		self.metadata = metadata
		self.configuration = configuration
	}
}

extension AbstractSecurityStructureConfiguration {
	public typealias ID = UUID
	public var id: ID {
		metadata.id
	}
}

// MARK: - ProfileSnapshot.AppliedSecurityStructure
extension ProfileSnapshot {
	/// A version of `AppliedSecurityStructure` which only contains IDs of factor sources, suitable for storage in Profile Snapshot.
	public typealias AppliedSecurityStructure = AbstractSecurityStructure<FactorInstance.ID>
}

public typealias SecurityStructureConfigurationReference = AbstractSecurityStructureConfiguration<FactorSourceID>

extension SecurityStructureConfigurationReference.Configuration.Role {
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
			metadata: metadata,
			configuration: configuration.asReference()
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
			metadata: reference.metadata,
			configuration: detailedSecurityStructureConfiguration(referenceConfiguration: reference.configuration)
		)
	}

	func detailedSecurityStructureConfiguration(
		referenceConfiguration reference: SecurityStructureConfigurationReference.Configuration
	) throws -> SecurityStructureConfigurationDetailed.Configuration {
		try .init(
			numberOfDaysUntilAutoConfirmation: reference.numberOfDaysUntilAutoConfirmation,
			primaryRole: detailedSecurityStructureRole(referenceRole: reference.primaryRole),
			recoveryRole: detailedSecurityStructureRole(referenceRole: reference.recoveryRole),
			confirmationRole: detailedSecurityStructureRole(referenceRole: reference.confirmationRole)
		)
	}

	func detailedSecurityStructureRole(
		referenceRole reference: RoleOfTier<FactorSourceID>
	) throws -> RoleOfTier<FactorSource> {
		func lookup(id: FactorSourceID) throws -> FactorSource {
			guard let factorSource = factorSources.first(where: { $0.id == id }) else {
				throw FactorSourceWithIDNotFound()
			}
			return factorSource
		}

		return try .init(
			uncheckedThresholdFactors: .init(validating: reference.thresholdFactors.map(lookup(id:))),
			superAdminFactors: .init(validating: reference.superAdminFactors.map(lookup(id:))),
			threshold: reference.threshold
		)
	}
}

extension SecurityStructureConfigurationDetailed.Configuration {
	public func asReference() -> SecurityStructureConfigurationReference.Configuration {
		.init(
			numberOfDaysUntilAutoConfirmation: numberOfDaysUntilAutoConfirmation,
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
	public func asReference() -> RoleOfTier<FactorSourceID> {
		try! .init(
			uncheckedThresholdFactors: .init(validating: thresholdFactors.map(\.id)),
			superAdminFactors: .init(validating: superAdminFactors.map(\.id)),
			threshold: threshold
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
		func decorate(
			_ keyPath: KeyPath<ProfileSnapshot.AppliedSecurityStructure, RoleOfTier<FactorInstance.ID>>
		) throws -> RoleOfTier<FactorInstance> {
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
				uncheckedThresholdFactors: .init(uncheckedUniqueElements: roleWithfactorInstanceIDs.thresholdFactors.map(lookup(id:))),
				superAdminFactors: .init(uncheckedUniqueElements: roleWithfactorInstanceIDs.superAdminFactors.map(lookup(id:))),
				threshold: roleWithfactorInstanceIDs.threshold
			)
		}

		return try! .init(
			numberOfDaysUntilAutoConfirmation: accessController.securityStructure.numberOfDaysUntilAutoConfirmation,
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
