import EngineKit
import FeaturePrelude

// MARK: - NonFungibleTokenList.Row.View
extension NonFungibleAssetList.Row {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleAssetList.Row>

		public init(store: StoreOf<NonFungibleAssetList.Row>) {
			self.store = store
		}
	}
}

extension NonFungibleAssetList.Row.View {
	public var body: some SwiftUI.View {
		WithViewStore(
			store,
			observe: identity,
			send: NonFungibleAssetList.Row.Action.view
		) { viewStore in
			if viewStore.resource.tokens.isEmpty {
				EmptyView()
			} else {
				StackedViewsLayout(isExpanded: viewStore.isExpanded) {
					rowView(viewStore)
						.zIndex(.infinity)
					ForEach(
						Array(
							assetsToDisplay(viewStore)
								.sorted(by: \.localId)
								.enumerated()
						),
						id: \.element
					) { index, item in
						componentView(with: viewStore, asset: item, index: index)
					}
				}
				.padding(.horizontal, .medium3)
			}
		}
	}

	private func rowView(_ viewStore: ViewStoreOf<NonFungibleAssetList.Row>) -> some SwiftUI.View {
		HStack {
			NFTThumbnail(viewStore.resource.iconURL, size: .small)

			VStack(alignment: .leading, spacing: .small2) {
				Text(viewStore.resource.name ?? "")
					.foregroundColor(.app.gray1)
					.textStyle(.secondaryHeader)

				Text(viewStore.supply)
					.font(.app.body2HighImportance)
					.foregroundColor(.app.gray2)
			}

			Spacer()
		}
		.padding(.horizontal, .medium1)
		.frame(height: headerHeight)
		.background(.app.white)
		.roundedCorners(viewStore.isExpanded ? .top : .allCorners, radius: .small1)
		.tokenRowShadow(!viewStore.isExpanded)
		.onTapGesture {
			viewStore.send(.isExpandedToggled, animation: .easeInOut)
		}
	}

	private func assetsToDisplay(_ viewStore: ViewStoreOf<NonFungibleAssetList.Row>) -> IdentifiedArrayOf<AccountPortfolio.NonFungibleResource.NonFungibleToken> {
		if !viewStore.isExpanded {
			return IdentifiedArrayOf(uniqueElements: viewStore.resource.tokens.prefix(Constants.collapsedCardsCount))
		}
		return viewStore.resource.tokens
	}

	private var headerHeight: CGFloat { HitTargetSize.small.frame.height + 2 * .medium1 }
}

// MARK: - Private Computed Properties
extension NonFungibleAssetList.Row.View {
	@ViewBuilder
	fileprivate func componentView(
		with viewStore: ViewStoreOf<NonFungibleAssetList.Row>,
		asset: AccountPortfolio.NonFungibleResource.NonFungibleToken,
		index: Int
	) -> some View {
		let isDisabled = viewStore.disabled.contains(asset.id)
		HStack {
			NFTIDView(
				id: asset.id.localId().toUserFacingString(),
				name: asset.name,
				description: asset.description,
				thumbnail: viewStore.isExpanded ? asset.keyImageURL : nil
			)
			if let selectedAssets = viewStore.selectedAssets {
				CheckmarkView(appearance: .dark, isChecked: selectedAssets.contains(asset.id))
			}
		}
		.opacity(isDisabled ? 0.35 : 1)
		.padding(.medium1)
		.frame(minHeight: headerHeight)
		.background(.app.white)
		.roundedCorners(
			.bottom,
			radius: viewStore.isExpanded && index != (viewStore.nftCount - 1) ? .zero : .small1
		)
		.tokenRowShadow(!viewStore.isExpanded)
		.scaleEffect(scale(isExpanded: viewStore.isExpanded, index: index))
		.zIndex(reversedZIndex(count: viewStore.nftCount, index: index))
		.onTapGesture { viewStore.send(.assetTapped(asset.id)) }
	}

	fileprivate func headerSupplyText(with viewStore: ViewStoreOf<NonFungibleAssetList.Row>) -> String {
		// TODO: remove when API is ready
		L10n.AssetDetails.supplyUnkown

		// TODO: update when API is ready
		/*
		 guard let supply = viewStore.containers.first?.asset.supply else {
		 	return L10n.AssetDetails.supplyUnkown
		 }

		 switch supply {
		 case let .fixed(value):
		 	return NSLocalizedString(L10n.AssetDetails.NFTDetails.ownedOfTotal(viewStore.containers.count, Int(value.magnitude)), comment: "Number of NFTs owned of total number")
		 case .mutable:
		 	return NSLocalizedString(L10n.AssetDetails.NFTDetails.nftPlural(viewStore.containers.count), comment: "Number of NFTs owned")
		 }
		 */
	}
}

private extension NonFungibleAssetList.Row.ViewState {
	var supply: String {
		resource.totalSupply.map {
			L10n.AssetDetails.NFTDetails.ownedOfTotal(
				nftCount,
				Int($0)
			)
		} ?? "\(nftCount)"
	}

	var nftCount: Int {
		resource.tokens.count
	}
}

private extension NonFungibleAssetList.Row.View {
	func reversedZIndex(count: Int, index: Int) -> Double {
		Double(count - index)
	}

	func scale(isExpanded: Bool, index: Int) -> CGFloat {
		if isExpanded {
			return 1
		} else {
			return 1 - CGFloat(min(index + 1, Constants.collapsedVisibleCardsCount)) * Constants.scale
		}
	}
}

// MARK: - NonFungibleAssetList.Row.View.Constants
extension NonFungibleAssetList.Row.View {
	fileprivate enum Constants {
		/// header card index
		static let headerIndex: Int = -1

		/// number of visible NFT cards in collapsed view, excluding header (top) card
		static let collapsedVisibleCardsCount = 2

		/// Even though `collapsedVisibleCardsCount` will be visible, we do collapse more cards
		/// so that the expand/collapse animation hides the addition/removal for the rest of the cards
		static let collapsedCardsCount = 6

		/// default scale for one card
		static let scale: CGFloat = 0.05
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct NonFungibleRow_Preview: PreviewProvider {
	static var previews: some View {
		NonFungibleAssetList.Row.View(
			store: .init(
				initialState: .previewValue,
				reducer: NonFungibleAssetList.Row()
			)
		)
	}
}

extension NonFungibleAssetList.Row.State {
	public static let previewValue = Self(
		resource: .init(resourceAddress: try! .init(validatingAddress: "resource_tdx_c_1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq40v2wv"), tokens: []),
		selectedAssets: nil
	)
}
#endif

extension AccountPortfolio.NonFungibleResource.NonFungibleToken {
	fileprivate var localId: NonFungibleLocalId {
		id.localId()
	}
}

// MARK: - NonFungibleLocalId + Comparable
extension NonFungibleLocalId: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		case let (.integer(value: lhs), .integer(value: rhs)):
			return lhs < rhs
		case let (lhs, rhs):
			return lhs.toUserFacingString() < rhs.toUserFacingString()
		}
	}
}
