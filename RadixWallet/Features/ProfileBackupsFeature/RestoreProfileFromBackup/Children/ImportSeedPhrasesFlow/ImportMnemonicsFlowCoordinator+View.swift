import ComposableArchitecture
import SwiftUI

// MARK: - ImportMnemonicsFlowCoordinator.View
extension ImportMnemonicsFlowCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ImportMnemonicsFlowCoordinator>

		init(store: StoreOf<ImportMnemonicsFlowCoordinator>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			Color.app.white
				.onFirstTask { @MainActor in
					await store.send(.view(.onFirstTask)).finish()
				}
				.destinations(with: store)
		}
	}
}

private extension StoreOf<ImportMnemonicsFlowCoordinator> {
	var destination: PresentationStoreOf<ImportMnemonicsFlowCoordinator.Destination> {
		func scopeState(state: State) -> PresentationState<ImportMnemonicsFlowCoordinator.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ImportMnemonicsFlowCoordinator>) -> some View {
		let destinationStore = store.destination

		// We are using `fullScreenCover` for two reasons:
		// 1. it fixes a bug where otherwise a secondary `ImportMnemonicControllingAccounts` screen's buttons are not pressable
		// 2. If fixes issue where user can dismiss screen with iOS gesture, which we dont want in this case
		return fullScreenCover(
			store: destinationStore,
			state: /ImportMnemonicsFlowCoordinator.Destination.State.importMnemonicControllingAccounts,
			action: ImportMnemonicsFlowCoordinator.Destination.Action.importMnemonicControllingAccounts,
			content: { importStore in
				ImportMnemonicControllingAccounts.View(store: importStore)
					.withNavigationBar {
						store.send(.view(.closeButtonTapped))
					}
			}
		)
	}
}
