import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - NonFungibleResourceAsset
extension NonFungibleResourceAsset {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleResourceAsset>

		public init(store: StoreOf<NonFungibleResourceAsset>) {
			self.store = store
		}
	}
}

extension NonFungibleResourceAsset.ViewState {
	var resourceBalance: ResourceBalance.ViewState {
		.nonFungible(.init(
			id: token.id,
			resourceImage: resourceImage,
			resourceName: resourceName,
			nonFungibleName: token.data?.name
		))
	}
}

extension NonFungibleResourceAsset.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			ResourceBalanceView(viewStore.resourceBalance, appearance: .compact) {
				viewStore.send(.resourceTapped)
			}
			.padding(.medium3)
		}
		.destinations(with: store)
	}
}

private extension StoreOf<NonFungibleResourceAsset> {
	var destination: PresentationStoreOf<NonFungibleResourceAsset.Destination> {
		func scopeState(state: State) -> PresentationState<NonFungibleResourceAsset.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<NonFungibleResourceAsset>) -> some View {
		let destinationStore = store.destination
		return fungibleTokenDetails(with: destinationStore)
	}

	private func fungibleTokenDetails(with destinationStore: PresentationStoreOf<NonFungibleResourceAsset.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /NonFungibleResourceAsset.Destination.State.details,
			action: NonFungibleResourceAsset.Destination.Action.details,
			content: { NonFungibleTokenDetails.View(store: $0) }
		)
	}
}
