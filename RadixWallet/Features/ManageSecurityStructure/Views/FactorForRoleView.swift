import ComposableArchitecture
import SwiftUI

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
