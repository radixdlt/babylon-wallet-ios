import FeaturePrelude
import ImportMnemonicFeature

// MARK: - ImportMnemonicsFlowCoordinator.View
extension ImportMnemonicsFlowCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportMnemonicsFlowCoordinator>

		public init(store: StoreOf<ImportMnemonicsFlowCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				Color.app.white
					.onFirstTask { @MainActor in
						await viewStore.send(.view(.onFirstTask)).finish()
					}
					// We are using `fullScreenCover` for two reasons:
					// 1. it fixes a bug where otherwise a secondary `ImportMnemonicControllingAccounts` screen's buttons are not pressable
					// 2. If fixes issue where user can dismiss screen with iOS gesture, which we dont want in this case
					.fullScreenCover(
						store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
						state: /ImportMnemonicsFlowCoordinator.Destinations.State.importMnemonicControllingAccounts,
						action: ImportMnemonicsFlowCoordinator.Destinations.Action.importMnemonicControllingAccounts,
						content: { importStore in
							NavigationView {
								ImportMnemonicControllingAccounts.View(store: importStore)
							}
						}
					)
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							CloseButton {
								viewStore.send(.view(.closeButtonTapped))
							}
							.foregroundColor(.app.white)
						}
					}
			}
		}
	}
}
