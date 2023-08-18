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
				ZStack {
					Color.app.white
						.onFirstTask { @MainActor in
							await viewStore.send(.view(.onFirstTask)).finish()
						}

					IfLetStore(
						store.scope(state: \.importingMnemonic, action: { .child(.importingMnemonic($0)) }),
						then: {
							ImportMnemonic.View(store: $0)
								.navigationTitle(L10n.ImportMnemonic.navigationTitle)
						}
					)
				}
			}
		}
	}
}
