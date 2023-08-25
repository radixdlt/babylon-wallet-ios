
import DesignSystem
import FeaturePrelude
import Profile

// MARK: - ManageSecurityStructureCoordinator.View
extension ManageSecurityStructureCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ManageSecurityStructureCoordinator>

		public init(store: StoreOf<ManageSecurityStructureCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStackStore(
				store.scope(state: \.path, action: { .child(.path($0)) })
			) {
				path(for: store.scope(state: \.root, action: { .child(.root($0)) }))

					// This is required to disable the animation of internal components during transition
					.transaction { $0.animation = nil }
			} destination: {
				path(for: $0)
			}
		}

		func path(
			for store: StoreOf<ManageSecurityStructureCoordinator.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .start:
					CaseLet(
						state: /ManageSecurityStructureCoordinator.Path.State.start,
						action: ManageSecurityStructureCoordinator.Path.Action.start,
						then: { ManageSecurityStructureStart.View(store: $0) }
					)
				case .simpleSetupFlow:
					CaseLet(
						state: /ManageSecurityStructureCoordinator.Path.State.simpleSetupFlow,
						action: ManageSecurityStructureCoordinator.Path.Action.simpleSetupFlow,
						then: { SimpleManageSecurityStructureFlow.View(store: $0) }
					)
				case .advancedSetupFlow:
					CaseLet(
						state: /ManageSecurityStructureCoordinator.Path.State.advancedSetupFlow,
						action: ManageSecurityStructureCoordinator.Path.Action.advancedSetupFlow,
						then: { AdvancedManageSecurityStructureFlow.View(store: $0) }
					)
				case .nameStructure:
					CaseLet(
						state: /ManageSecurityStructureCoordinator.Path.State.nameStructure,
						action: ManageSecurityStructureCoordinator.Path.Action.nameStructure,
						then: { NameSecurityStructure.View(store: $0) }
					)
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ManageSecurityStructure_Preview
struct ManageSecurityStructure_Preview: PreviewProvider {
	static var previews: some View {
		ManageSecurityStructureCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: ManageSecurityStructureCoordinator()
			)
		)
	}
}

extension ManageSecurityStructureCoordinator.State {
	public static let previewValue = Self()
}
#endif
