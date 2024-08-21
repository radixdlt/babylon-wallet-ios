// MARK: - HideAsset.View
public extension HideAsset {
	struct View: SwiftUI.View {
		private let store: StoreOf<HideAsset>

		public init(store: StoreOf<HideAsset>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				if store.shouldShow {
					Button(L10n.AssetDetails.HideAsset.button) {
						store.send(.view(.buttonTapped))
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
					.padding(.horizontal, .medium3)
				}
			}
			.task {
				await store.send(.view(.task)).finish()
			}
			.destination(store: store)
		}
	}
}

private extension StoreOf<HideAsset> {
	var destination: PresentationStoreOf<HideAsset.Destination> {
		func scopeState(state: State) -> PresentationState<HideAsset.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destination(store: StoreOf<HideAsset>) -> some View {
		let destinationStore = store.destination
		return confirmation(with: destinationStore, store: store)
	}

	private func confirmation(with destinationStore: PresentationStoreOf<HideAsset.Destination>, store: StoreOf<HideAsset>) -> some View {
		sheet(store: destinationStore.scope(state: \.confirmation, action: \.confirmation)) { _ in
			ConfirmationView(configuration: .hideAsset) { action in
				store.send(.destination(.presented(.confirmation(action))))
			}
		}
	}
}
