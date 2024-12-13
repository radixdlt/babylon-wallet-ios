// MARK: - DeviceFactorSourceDetail.View

extension DeviceFactorSourceDetail {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DeviceFactorSourceDetail>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { _ in
				// TODO: implement
				Text("Implement: DeviceFactorSourceDetail")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { store.send(.view(.appeared)) }
			}
		}
	}
}
