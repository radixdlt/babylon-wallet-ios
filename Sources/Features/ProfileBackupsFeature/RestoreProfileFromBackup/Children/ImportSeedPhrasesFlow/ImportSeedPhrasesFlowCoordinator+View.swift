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
				//				ZStack {
				Color.app.white
					.onFirstTask { @MainActor in
						await viewStore.send(.view(.onFirstTask)).finish()
					}
					.sheet(
						store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
						state: /ImportMnemonicsFlowCoordinator.Destinations.State.importMnemonicControllingAccounts,
						action: ImportMnemonicsFlowCoordinator.Destinations.Action.importMnemonicControllingAccounts,
						content: { ImportMnemonicControllingAccounts.View(store: $0) }
					)

				//					IfLetStore(
				//						store.scope(
				//                            state: \.importingMnemonicControllingAccounts,
				//                            action: { .child(.importingMnemonicControllingAccounts($0)) }
				//                        ),
				//						then: {
				//                            ImportMnemonicControllingAccounts.View(store: $0)
				//								.navigationTitle(L10n.ImportMnemonic.navigationTitle)
				//						}
				//					)
			}
		}
	}
}
