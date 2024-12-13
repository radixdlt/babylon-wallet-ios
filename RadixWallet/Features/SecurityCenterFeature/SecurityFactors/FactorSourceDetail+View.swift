// MARK: - DeviceFactorSourceDetail.View

extension FactorSourceDetail {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<FactorSourceDetail>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				// TODO: implement
				Text("Details of \(viewStore.integrity.factorSource)")
					.onAppear { store.send(.view(.appeared)) }
			}
		}
	}
}
