import FeaturePrelude

extension DappInteractionCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DappInteractionCoordinator>

		var body: some SwiftUI.View {
			SwitchStore(store) {
				CaseLet(
					state: /DappInteractionCoordinator.State.loading,
					action: { DappInteractionCoordinator.Action.child(.loading($0)) },
					then: { DappInteractionLoading.View(store: $0) }
				)
				CaseLet(
					state: /DappInteractionCoordinator.State.flow,
					action: { DappInteractionCoordinator.Action.child(.flow($0)) },
					then: { DappInteractionFlow.View(store: $0) }
				)
			}
			.transition(.opacity)
		}
	}
}
