import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - NonFungibleResourceAsset
extension NonFungibleResourceAsset {
	typealias ViewState = State

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleResourceAsset>

		init(store: StoreOf<NonFungibleResourceAsset>) {
			self.store = store
		}
	}
}

extension NonFungibleResourceAsset.ViewState {
	var resourceBalance: ResourceBalance.ViewState {
		.nonFungible(.init(
			id: token.id,
			resourceImage: resource.metadata.iconURL,
			resourceName: resource.metadata.name,
			nonFungibleName: token.data?.name,
			amount: nil
		))
	}
}

extension NonFungibleResourceAsset.View {
	var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			ResourceBalanceView(viewStore.resourceBalance, appearance: .compact) {
				viewStore.send(.resourceTapped)
			}
			.padding(.medium3)
		}
	}
}
