import ComposableArchitecture
import SwiftUI

// MARK: - NonFungibleResourceAsset
public struct NonFungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = String
		public var id: ID { token.id.asStr() }

		public let resourceImage: URL?
		public let resourceName: String?
		public let resourceAddress: ResourceAddress
		public let token: OnLedgerEntity.NonFungibleToken
	}
}

extension NonFungibleResourceAsset {
	public typealias ViewState = ResourceBalance.ViewState // FIXME: GK use .nonFungbile

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleResourceAsset>
		public init(store: StoreOf<NonFungibleResourceAsset>) {
			self.store = store
		}
	}
}

extension NonFungibleResourceAsset.State {
	var viewState: NonFungibleResourceAsset.ViewState {
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
		WithViewStore(store, observe: \.viewState) { viewStore in
			ResourceBalanceView(viewStore.state, appearance: .compact)
				.padding(.medium3)
		}
	}
}
