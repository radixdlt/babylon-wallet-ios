import FeaturePrelude

// MARK: - AdvancedManageSecurityStructureFlow.View
extension AdvancedManageSecurityStructureFlow {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AdvancedManageSecurityStructureFlow>

		public init(store: StoreOf<AdvancedManageSecurityStructureFlow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack {
						FactorsForRoleButton(role: .primary) {
							viewStore.send(.primaryRoleButtonTapped)
						}

						FactorsForRoleButton(role: .recovery) {
							viewStore.send(.recoveryRoleButtonTapped)
						}

						FactorsForRoleButton(role: .confirmation) {
							viewStore.send(.confirmationRoleButtonTapped)
						}
					}
					.padding()
					.destinations(store: store)
				}
			}
		}
	}
}

extension View {
	@MainActor
	fileprivate func destinations(store: StoreOf<AdvancedManageSecurityStructureFlow>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
		return factorsForRoleSheet(with: destinationStore)
	}

	@MainActor
	private func factorsForRoleSheet(with destinationStore: PresentationStoreOf<AdvancedManageSecurityStructureFlow.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /AdvancedManageSecurityStructureFlow.Destinations.State.factorsForRole,
			action: AdvancedManageSecurityStructureFlow.Destinations.Action.factorsForRole,
			content: { FactorsForRole.View(store: $0) }
		)
	}
}

extension RoleOfTier {
	var isEmpty: Bool {
		superAdminFactors.isEmpty && thresholdFactors.isEmpty
	}
}

// MARK: - FactorsForRoleButton
struct FactorsForRoleButton: SwiftUI.View {
	let role: SecurityStructureRole
	let action: () -> Void

	init(
		role: SecurityStructureRole,
		action: @escaping () -> Void
	) {
		self.role = role
		self.action = action
	}

	var body: some View {
		VStack(alignment: .leading, spacing: .medium2) {
			Text(role.titleAdvancedFlow)
				.font(.app.sectionHeader)

			Text(role.subtitleAdvancedFlow)
				.font(.app.body2Header)
				.foregroundColor(.app.gray3)

			Button(action: action) {
				HStack {
					// FIXME: Strings
					Text("None set")
						.font(.app.body1Header)

					Spacer(minLength: 0)

					Image(asset: AssetResource.chevronRight)
				}
			}
			.cornerRadius(.medium2)
			.frame(maxWidth: .infinity)
			.padding()
			.background(.app.gray5)
		}
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
