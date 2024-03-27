// MARK: - RoleProtocol

public protocol RoleProtocol: Sendable, Hashable {
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

// MARK: - RoleOfTier
public struct RoleOfTier<Role: RoleProtocol, AbstractFactor>:
	Sendable, Hashable, Codable
	where
	AbstractFactor: FactorOfTierProtocol & Sendable & Hashable & Codable
{
	public static var role: SecurityStructureRole {
		Role.role
	}

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
	) throws {
		let role = Role.role
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

	init(
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
		single(factor.embed(), for: role)
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
