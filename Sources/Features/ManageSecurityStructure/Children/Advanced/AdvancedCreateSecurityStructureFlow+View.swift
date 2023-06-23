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
			ScrollView {
				VStack {
					FactorsForRole.View(
						store: store.scope(
							state: \.primaryRole,
							action: { .child(.primaryRole($0)) }
						)
					)

					FactorsForRole.View(
						store: store.scope(
							state: \.recoveryRole,
							action: { .child(.recoveryRole($0)) }
						)
					)

					FactorsForRole.View(
						store: store.scope(
							state: \.confirmationRole,
							action: { .child(.confirmationRole($0)) }
						)
					)
				}
			}
		}
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
