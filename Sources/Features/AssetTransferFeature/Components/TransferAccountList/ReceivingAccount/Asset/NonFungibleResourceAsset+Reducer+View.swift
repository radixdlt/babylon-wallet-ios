import FeaturePrelude

// MARK: - NonFungibleResourceAsset
public struct NonFungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = ResourceAddress
		public var id: ID {
			resourceAddress.nftGlobalId(nftToken.id)
		}

		public let resourceImage: URL?
		public let resourceName: String?
		public let resourceAddress: ResourceAddress
		public let nftToken: AccountPortfolio.NonFungibleResource.NonFungibleToken
	}
}

extension NonFungibleResourceAsset {
	public typealias ViewState = TransferNFTView.ViewState

	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store<NonFungibleResourceAsset.State, Never>
		public init(store: Store<NonFungibleResourceAsset.State, Never>) {
			self.store = store
		}
	}
}

extension NonFungibleResourceAsset.State {
	var viewState: NonFungibleResourceAsset.ViewState {
		.init(
			tokenID: nftToken.id.rawValue.userFacingNonFungibleLocalID,
			tokenName: nftToken.name,
			thumbnail: resourceImage
		)
	}
}

extension NonFungibleResourceAsset.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState) { viewStore in
			TransferNFTView(viewState: viewStore.state)
				.frame(height: .largeButtonHeight)
		}
	}
}
