import SwiftUI

// MARK: - ___VARIABLE_featureName___.View
public extension ___VARIABLE_featureName___ {
	struct View: SwiftUI.View {
		private let store: StoreOf<___VARIABLE_featureName___>

		public init(store: StoreOf<___VARIABLE_featureName___>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				// TODO: implement
				Text("Implement: ___VARIABLE_featureName___")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { store.send(.view(.appeared)) }
			}
		}
	}
}
