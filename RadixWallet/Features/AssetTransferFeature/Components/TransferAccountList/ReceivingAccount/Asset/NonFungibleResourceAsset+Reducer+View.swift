import ComposableArchitecture
import SwiftUI

// MARK: - NonFungibleResourceAsset
public struct NonFungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = String
		public var id: ID { nftToken.id.asStr() }

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
	public typealias ViewState = TransferNFTView.ViewState

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
		.init(
			tokenID: nftToken.id.localId().toUserFacingString(),
			tokenName: nftToken.data?.name,
			thumbnail: resourceImage
		)
	}
}

extension NonFungibleResourceAsset.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState) { viewStore in
			TransferNFTView(viewState: viewStore.state, background: .app.white)
				.frame(height: .largeButtonHeight)
		}
	}
}
