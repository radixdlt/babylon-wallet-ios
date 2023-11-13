import ComposableArchitecture
import SwiftUI

// MARK: - ImportMnemonicsFlowCoordinator.View
extension ImportMnemonicsFlowCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportMnemonicsFlowCoordinator>

		public init(store: StoreOf<ImportMnemonicsFlowCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			Color.app.white
				.onFirstTask { @MainActor in
					await store.send(.view(.onFirstTask)).finish()
				}
				.destinations(with: store)
		}
	}
}

private extension StoreOf<ImportMnemonicsFlowCoordinator> {
	var destination: PresentationStoreOf<ImportMnemonicsFlowCoordinator.Destination_> {
		scope(state: \.$destination) { .destination($0) }
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
			state: /ImportMnemonicsFlowCoordinator.Destination_.State.importMnemonicControllingAccounts,
			action: ImportMnemonicsFlowCoordinator.Destination_.Action.importMnemonicControllingAccounts,
			content: { importStore in
				ImportMnemonicControllingAccounts.View(store: importStore)
					.withNavigationBar {
						store.send(.view(.closeButtonTapped))
					}
			}
		)
	}
}
