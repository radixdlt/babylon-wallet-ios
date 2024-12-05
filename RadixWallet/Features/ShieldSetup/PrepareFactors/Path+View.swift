import SwiftUI

// MARK: - PrepareFactors.Coordinator.View
extension PrepareFactors.Path {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<PrepareFactors.Path>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				switch store.state {
				case .intro:
					PrepareFactors.IntroView {
						store.send(.introFinished)
					}
				case .addFactor:
					if let store = store.scope(state: \.addFactor, action: \.addFactor) {
						PrepareFactors.AddFactor.View(store: store)
					}
				case .completion:
					PrepareFactors.CompletionView {
						store.send(.completionFinished)
					}
				}
			}
		}
	}
}
