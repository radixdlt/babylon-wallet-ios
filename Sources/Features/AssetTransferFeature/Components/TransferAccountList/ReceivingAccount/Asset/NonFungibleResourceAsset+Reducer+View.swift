import FeaturePrelude

// MARK: - NonFungibleResourceAsset
public struct NonFungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = String
		public var id: ID {
			resourceAddress.nftGlobalId(nftToken.id).formatted
		}

		public let resourceAddress: ResourceAddress
		public let nftToken: AccountPortfolio.NonFungibleResource.NonFungibleToken
	}
}

extension NonFungibleResourceAsset {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store<NonFungibleResourceAsset.State, Never>
		public init(store: Store<NonFungibleResourceAsset.State, Never>) {
			self.store = store
		}
	}
}

extension NonFungibleResourceAsset.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }) { viewStore in
			TransferNFTView(
				name: viewStore.nftToken.userFacingID,
				thumbnail: viewStore.nftToken.keyImageURL
			)
			.frame(height: .largeButtonHeight)
		}
	}
}
