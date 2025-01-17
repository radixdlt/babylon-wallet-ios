// MARK: - ___VARIABLE_featureName___.View

extension ___VARIABLE_featureName___ {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<___VARIABLE_featureName___>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { _ in
				// TODO: implement
				Text("Implement: ___VARIABLE_featureName___")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { store.send(.view(.appeared)) }
			}
		}
	}
}
