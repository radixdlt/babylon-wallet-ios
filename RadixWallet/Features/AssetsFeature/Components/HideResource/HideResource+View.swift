// MARK: - HideResource.View
public extension HideResource {
	struct View: SwiftUI.View {
		private let store: StoreOf<HideResource>

		public init(store: StoreOf<HideResource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				if store.shouldShow {
					Button(store.title) {
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

private extension StoreOf<HideResource> {
	var destination: PresentationStoreOf<HideResource.Destination> {
		func scopeState(state: State) -> PresentationState<HideResource.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destination(store: StoreOf<HideResource>) -> some View {
		let destinationStore = store.destination
		return confirmation(with: destinationStore, store: store)
	}

	private func confirmation(with destinationStore: PresentationStoreOf<HideResource.Destination>, store: StoreOf<HideResource>) -> some View {
		sheet(store: destinationStore.scope(state: \.confirmation, action: \.confirmation)) { _ in
			ConfirmationView(kind: store.confirmationKind) { action in
				store.send(.destination(.presented(.confirmation(action))))
			}
		}
	}
}

private extension HideResource.State {
	var title: String {
		switch kind {
		case .fungible, .poolUnit:
			L10n.AssetDetails.hideAsset
		case .nonFungible:
			L10n.AssetDetails.hideCollection
		}
	}

	var confirmationKind: ConfirmationView.Kind {
		switch kind {
		case .fungible, .poolUnit:
			.hideAsset
		case let .nonFungible(_, name):
			.hideCollection(name: name ?? "")
		}
	}
}
