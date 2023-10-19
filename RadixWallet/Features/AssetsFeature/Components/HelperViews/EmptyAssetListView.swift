import ComposableArchitecture
import SwiftUI

// MARK: - EmptyAssetListView
struct EmptyAssetListView: View {
	struct ViewState {
		let imageAsset: ImageAsset
		let description: String
	}

	let viewState: ViewState

	var body: some View {
		VStack(spacing: .medium1) {
			Image(asset: viewState.imageAsset)
			Text(viewState.description)
				.foregroundColor(.app.gray1)
				.textStyle(.sectionHeader)
		}
		.padding(.top, .medium1)
		.centered
		.listRowBackground(Color.clear)
	}
}

extension EmptyAssetListView {
	static var fungibleResources: Self {
		.init(viewState: .init(imageAsset: AssetResource.fungibleTokens, description: L10n.AssetDetails.TokenDetails.noTokens))
	}

	static var nonFungibleResources: Self {
		.init(viewState: .init(imageAsset: AssetResource.nonfungbileTokens, description: L10n.AssetDetails.NFTDetails.noNfts))
	}

	static var poolUnits: Self {
		.init(viewState: .init(imageAsset: AssetResource.poolUnits, description: L10n.AssetDetails.PoolUnitDetails.noPoolUnits))
	}
}
