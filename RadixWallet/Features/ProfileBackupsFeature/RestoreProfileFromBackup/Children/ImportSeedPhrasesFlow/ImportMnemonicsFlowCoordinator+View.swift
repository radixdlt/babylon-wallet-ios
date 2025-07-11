import ComposableArchitecture
import SwiftUI

// MARK: - ImportMnemonicsFlowCoordinator.View
extension ImportMnemonicsFlowCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<ImportMnemonicsFlowCoordinator>

		init(store: StoreOf<ImportMnemonicsFlowCoordinator>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack(path: $store.scope(state: \.path, action: \.child.path)) {
					VStack {
						ProgressView("Processing Profile")
					}
					.background(.secondaryBackground)
					.onFirstTask { @MainActor in
						await store.send(.view(.onFirstTask)).finish()
					}
				} destination: { destinationStore in
					if let importMnemonicStore = destinationStore.scope(state: \.importMnemonic, action: \.importMnemonic) {
						ImportMnemonicForFactorSource.View(store: importMnemonicStore)
							.navigationBarBackButtonHidden()
							.radixToolbar(title: "Enter Seed Phrase") {
								// close action
							}
					}
				}
			}
		}
	}
}
