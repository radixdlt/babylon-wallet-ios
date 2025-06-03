import ComposableArchitecture
import SwiftUI

// MARK: - EmptyAssetListView
struct EmptyAssetListView: View {
	struct ViewState: Sendable, Equatable {
		let imageAsset: ImageAsset
		let description: String
		let glossaryItem: InfoLinkSheet.GlossaryItem
		let glossaryLabel: String
	}

	let viewState: ViewState

	init(_ viewState: ViewState) {
		self.viewState = viewState
	}

	var body: some View {
		VStack(spacing: .large2) {
			Image(asset: viewState.imageAsset)
			Text(viewState.description)
				.foregroundColor(.primaryText)
				.textStyle(.sectionHeader)

			InfoButton(viewState.glossaryItem, label: viewState.glossaryLabel)
		}
		.padding(.top, .large2)
		.centered
		.listRowBackground(Color.clear)
	}
}

extension EmptyAssetListView.ViewState {
	static let fungibleResources = Self(
		imageAsset: AssetResource.fungibleTokens,
		description: L10n.AssetDetails.TokenDetails.noTokens,
		glossaryItem: .tokens,
		glossaryLabel: L10n.InfoLink.Title.tokens
	)

	static let nonFungibleResources = Self(
		imageAsset: AssetResource.nft,
		description: L10n.AssetDetails.NFTDetails.noNfts,
		glossaryItem: .nfts,
		glossaryLabel: L10n.InfoLink.Title.nfts
	)

	static let stakes = Self(
		imageAsset: AssetResource.stakes,
		description: L10n.AssetDetails.StakingDetails.noStakes,
		glossaryItem: .networkstaking,
		glossaryLabel: L10n.InfoLink.Title.networkstaking
	)

	static let poolUnits = Self(
		imageAsset: AssetResource.poolUnits,
		description: L10n.AssetDetails.PoolUnitDetails.noPoolUnits,
		glossaryItem: .poolunits,
		glossaryLabel: L10n.InfoLink.Title.poolunits
	)
}
