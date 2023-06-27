import FeaturePrelude

// MARK: - FactorForRoleView
public struct FactorForRoleView<Role: RoleProtocol, Factor: FactorSourceProtocol>: SwiftUI.View {
	public let factorSet: Factor?
	public let action: () -> Void

	public init(
		factorSet: Factor? = nil,
		action: @escaping () -> Void
	) {
		self.factorSet = factorSet
		self.action = action
	}

	public var body: some View {
		SelectFactorView(
			title: Role.titleSimpleFlow,
			subtitle: Role.subtitleSimpleFlow,
			factorSet: factorSet,
			action: action
		)
		.frame(maxWidth: .infinity)
	}
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
