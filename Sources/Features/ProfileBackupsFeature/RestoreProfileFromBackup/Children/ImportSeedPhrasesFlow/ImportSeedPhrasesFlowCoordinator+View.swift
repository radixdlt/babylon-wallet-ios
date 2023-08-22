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
					.sheet(
						store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
						state: /ImportMnemonicsFlowCoordinator.Destinations.State.importMnemonicControllingAccounts,
						action: ImportMnemonicsFlowCoordinator.Destinations.Action.importMnemonicControllingAccounts,
						content: { importStore in
							NavigationView {
								ImportMnemonicControllingAccounts.View(store: importStore)
							}
						}
					)
			}
		}
	}
}
