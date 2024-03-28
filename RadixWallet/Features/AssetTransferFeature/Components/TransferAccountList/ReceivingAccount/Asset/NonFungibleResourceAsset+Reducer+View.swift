import ComposableArchitecture
import SwiftUI

// MARK: - NonFungibleResourceAsset
public struct NonFungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = String
		public var id: ID { nftToken.id.description }

		public let resourceImage: URL?
		public let resourceName: String?
		public let resourceAddress: ResourceAddress
		public let nftToken: OnLedgerEntity.NonFungibleToken
		public var nftGlobalID: NonFungibleGlobalId {
			nftToken.id
		}
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
			id: nftToken.id,
			resourceImage: resourceImage,
			resourceName: resourceName,
			nonFungibleName: nftToken.data?.name
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
