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
			Section {
				if viewStore.isExpanded {
					ForEach(
						Array(
							viewStore.tokens.enumerated()
						),
						id: \.offset
					) { index, item in
						componentView(with: viewStore, asset: item, index: index)
							.listRowBackground(Color.white.roundedCorners(.allCorners, radius: .zero))
							.onAppear {
								print("Appeared index \(index)")
							}
					}
				}
			} header: {
				ZStack {
					rowView(viewStore)
						.zIndex(.infinity)
					if !viewStore.isExpanded {
						ForEach(0 ..< Constants.collapsedVisibleCardsCount) { index in
							collapsedPlaceholderView(index)
								.offset(y: CGFloat(index) * .small1)
						}
					} else {
						Divider()
					}
				}
				.listRowInsets(.init(top: .zero, leading: .zero, bottom: 3, trailing: .zero))
			}
			.onAppear {
				viewStore.send(.didAppear)
			}
		}
	}

	private func rowView(_ viewStore: ViewStoreOf<NonFungibleAssetList.Row>) -> some SwiftUI.View {
		HStack(spacing: .small1) {
			NFTThumbnail(viewStore.resource.metadata.iconURL, size: .small)

			VStack(alignment: .leading, spacing: .small2) {
				Text(viewStore.resource.metadata.name ?? "")
					.foregroundColor(.app.gray1)
					.lineSpacing(-4)
					.textStyle(.secondaryHeader)

				Text("\(viewStore.resource.nonFungibleIdsCount)")
					.font(.app.body2HighImportance)
					.foregroundColor(.app.gray2)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.horizontal, .medium1)
		.frame(height: headerHeight)
		.background(.app.white)
		.roundedCorners(viewStore.isExpanded ? .top : .allCorners, radius: .small1)
		.tokenRowShadow(!viewStore.isExpanded)
		.onTapGesture {
			viewStore.send(.isExpandedToggled, animation: .easeInOut)
		}
	}

	private func assetsToDisplay(_ viewStore: ViewStoreOf<NonFungibleAssetList.Row>) -> IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken> {
		// Put in placeholder items?
//		if !viewStore.isExpanded {
//			return IdentifiedArrayOf(uniqueElements: viewStore.loadedTokens.prefix(Constants.collapsedCardsCount))
//		}
		viewStore.loadedTokens
	}

	private var headerHeight: CGFloat { HitTargetSize.small.frame.height + 2 * .medium1 }
}

// MARK: - Private Computed Properties
extension NonFungibleAssetList.Row.View {
	@ViewBuilder
	fileprivate func collapsedPlaceholderView(_ index: Int) -> some View {
		Spacer()
			// .padding(.medium1)
			.frame(maxWidth: .infinity, minHeight: headerHeight)
			.background(.app.white)
			.roundedCorners(
				.bottom,
				radius: .small1
			)
			.tokenRowShadow(true)
			.scaleEffect(scale(isExpanded: false, index: index))
			.zIndex(reversedZIndex(count: Constants.collapsedCardsCount, index: index))
	}

	@ViewBuilder
	fileprivate func componentView(
		with viewStore: ViewStoreOf<NonFungibleAssetList.Row>,
		asset: Loadable<OnLedgerEntity.NonFungibleToken>,
		index: Int
	) -> some View {
		// let isDisabled = viewStore.disabled.contains(asset.id)
		HStack {
			NFTIDView(
				id: asset.id.map { $0.localId().toUserFacingString() },
				name: asset.data.name,
				thumbnail: asset.data.keyImageURL
			)
//			if let selectedAssets = viewStore.selectedAssets {
//				CheckmarkView(appearance: .dark, isChecked: selectedAssets.contains(asset))
//			}
		}
		// .opacity(isDisabled ? 0.35 : 1)
		.padding(.medium1)
		.frame(minHeight: headerHeight)
		.background(.app.white)
		////		.roundedCorners(
		////			.bottom,
		////			radius: index != (viewStore.loadedTokens.count - 1) ? .zero : .small1
		////		)
		// .onTapGesture { viewStore.send(.assetTapped(asset)) }
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
		static let collapsedCardsCount = 2

		/// default scale for one card
		static let scale: CGFloat = 0.05
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
// struct NonFungibleRow_Preview: PreviewProvider {
//	static var previews: some View {
//		NonFungibleAssetList.Row.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: NonFungibleAssetList.Row.init
//			)
//		)
//	}
// }
//
// extension NonFungibleAssetList.Row.State {
//	private static let previewResource = AccountPortfolio.NonFungibleResource(
//        resourceAddress: previewResourceAddress,
//		atLedgerState: .init(version: 0),
//        nonFungibleIds: [],
//        metadata: .init()
//	)
//
//	private static let previewResourceAddress = try! ResourceAddress(validatingAddress: "resource_tdx_c_1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq40v2wv")
// }
// #endif

extension OnLedgerEntity.NonFungibleToken {
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
