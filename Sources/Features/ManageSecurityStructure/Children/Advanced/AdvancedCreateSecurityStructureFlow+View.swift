import FeaturePrelude

// MARK: - AdvancedManageSecurityStructureFlow.View
extension AdvancedManageSecurityStructureFlow {
	public struct ViewState: Equatable {
		let confirmationRole: SecurityStructureConfigurationDetailed.Configuration.Confirmation

		init(state: AdvancedManageSecurityStructureFlow.State) {
			switch state.mode {
			case let .existing(existing):
				self.confirmationRole = existing.configuration.confirmationRole
			case let .new(new):
				self.confirmationRole = new.confirmationRole
			}
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AdvancedManageSecurityStructureFlow>

		public init(store: StoreOf<AdvancedManageSecurityStructureFlow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: { AdvancedManageSecurityStructureFlow.ViewState(state: $0) },
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					VStack {
						RoleView<ConfirmationRoleTag>(
							role: viewStore.confirmationRole
						) {
							viewStore.send(.confirmationRoleFactorsButtonTapped)
						}
					}
				}
			}
		}
	}
}

// MARK: - RoleView
public struct RoleView<Role: RoleProtocol>: SwiftUI.View {
	public let role: RoleOfTier<Role, FactorSource>
	public let action: () -> Void

	public init(
		role: RoleOfTier<Role, FactorSource>,
		action: @escaping () -> Void
	) {
		self.role = role
		self.action = action
	}

	public var body: some SwiftUI.View {
		VStack(alignment: .leading, spacing: .medium2) {
			Text(Role.titleAdvancedFlow)
				.font(.app.sectionHeader)

			Text(Role.subtitleAdvancedFlow)
				.font(.app.body2Header)
				.foregroundColor(.app.gray3)

			Button(action: action) {
				HStack {
					// FIXME: Strings
					Text("None set")
						.font(.app.body1Header)
						.foregroundColor(role.isEmpty ? .app.gray3 : .app.gray1)

					Spacer(minLength: 0)

					Image(asset: AssetResource.chevronRight)
				}
			}
			.cornerRadius(.medium2)
			.frame(maxWidth: .infinity)
			.padding()
			.background(.app.gray5)
		}
		.padding()
		.frame(maxWidth: .infinity)
	}
}

extension RoleOfTier {
	var isEmpty: Bool {
		superAdminFactors.isEmpty && thresholdFactors.isEmpty
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - AdvancedManageSecurityStructureFlow_Preview
// struct AdvancedManageSecurityStructureFlow_Preview: PreviewProvider {
//	static var previews: some View {
//		AdvancedManageSecurityStructureFlow.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: AdvancedManageSecurityStructureFlow()
//			)
//		)
//	}
// }
//
// extension AdvancedManageSecurityStructureFlow.State {
//	public static let previewValue = Self()
// }
// #endif
