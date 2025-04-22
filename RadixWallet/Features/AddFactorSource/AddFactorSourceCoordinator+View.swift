import SwiftUI

// MARK: - AddFactorSource
enum AddFactorSource {}

// MARK: - AddFactorSource.Coordinator.View
extension AddFactorSource.Coordinator {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<AddFactorSource.Coordinator>
		@Environment(\.dismiss) var dismiss

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack(path: $store.scope(state: \.path, action: \.child.path)) {
					path(for: store.scope(state: \.root, action: \.child.root))
						.toolbar {
							ToolbarItem(placement: .navigationBarLeading) {
								CloseButton {
									dismiss()
								}
							}
						}
				} destination: { destination in
					path(for: destination)
				}
			}
		}

		@ViewBuilder
		private func path(for store: StoreOf<AddFactorSource.Coordinator.Path>) -> some SwiftUI.View {
			switch store.state {
			case .intro:
				AddFactorSource.IntroView(kind: self.store.kind) {
					self.store.send(.view(.continueButtonTapped))
				}
			case .deviceSeedPhrase:
				if let store = store.scope(state: \.deviceSeedPhrase, action: \.deviceSeedPhrase) {
					AddFactorSource.DeviceSeedPhrase.View(store: store)
				}
			case .confirmSeedPhrase:
				if let store = store.scope(state: \.confirmSeedPhrase, action: \.confirmSeedPhrase) {
					AddFactorSource.ConfirmSeedPhrase.View(store: store)
				}
			case .nameFactorSource:
				if let store = store.scope(state: \.nameFactorSource, action: \.nameFactorSource) {
					AddFactorSource.NameFactorSource.View(store: store)
				}
			}
		}
	}
}
