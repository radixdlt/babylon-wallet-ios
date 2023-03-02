import FeaturePrelude

// MARK: - NonFungibleTokenList.Row.View
extension NonFungibleTokenList.Row {
	struct ViewState: Equatable {
		let container: NonFungibleTokenContainer
		var isExpanded: Bool

		init(state: NonFungibleTokenList.Row.State) {
			container = state.container
			isExpanded = state.isExpanded
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleTokenList.Row>

		@SwiftUI.State private var expandedHeight: CGFloat = .zero
		@SwiftUI.State private var rowHeights: [Int: CGFloat] = [:] {
			didSet {
				expandedHeight = rowHeights.map(\.value).reduce(0, +)
			}
		}

		public init(store: StoreOf<NonFungibleTokenList.Row>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ViewState.init(state:),
				send: { .view($0) }
			) { viewStore in
				VStack(spacing: .small3 / 2) {
					if viewStore.container.assets.isEmpty {
						EmptyView()
					} else {
						ForEach(Constants.headerIndex ..< nftCount(with: viewStore), id: \.self) { index in
							Group {
								switch index {
								case -1:
									headerView(with: viewStore, index: index)
								default:
									componentView(with: viewStore, index: index)
								}
							}
							.onSizeChanged { size in
								if rowHeights[index] == nil {
									rowHeights[index] = size.height
								} else {
									withAnimation {
										rowHeights[index] = size.height
									}
								}
							}
						}
						.padding(.horizontal, .medium3)
					}
				}
				.frame(height: viewStore.isExpanded ? expandedHeight : collapsedHeight(with: viewStore), alignment: .top)
			}
		}
	}
}

// MARK: - NonFungibleTokenList.Row.View.ViewStore
extension NonFungibleTokenList.Row.View {
	fileprivate typealias ViewStore = ComposableArchitecture.ViewStore<NonFungibleTokenList.Row.ViewState, NonFungibleTokenList.Row.ViewAction>
}

// MARK: - Private Methods
extension NonFungibleTokenList.Row.View {
	fileprivate func scale(with viewStore: ViewStore, index: Int) -> CGFloat {
		if index >= Constants.cardLimit {
			return viewStore.isExpanded ? 1 : 1 - (CGFloat(Constants.cardLimit) * Constants.scale)
		} else {
			return viewStore.isExpanded ? 1 : 1 - (CGFloat(index + 1) * Constants.scale)
		}
	}

	fileprivate func offset(with viewStore: ViewStore, index: Int) -> CGFloat {
		if index >= Constants.cardLimit {
			return viewStore.isExpanded ? 0 : CGFloat((index + 1) * Constants.nonVisibleCardOffset)
		} else {
			return viewStore.isExpanded ? 0 : CGFloat((index + 1) * Constants.visibleCardOffset)
		}
	}

	fileprivate func reversedZIndex(count: Int, index: Int) -> Double {
		Double(count - index)
	}
}

// MARK: - Private Computed Properties
extension NonFungibleTokenList.Row.View {
	fileprivate func headerView(with viewStore: ViewStore, index: Int) -> some View {
		Header(
			name: viewStore.container.name ?? "",
			iconAsset: headerIconAsset,
			isExpanded: viewStore.isExpanded
		)
		.zIndex(reversedZIndex(count: nftCount(with: viewStore), index: index))
		.onTapGesture {
			viewStore.send(.isExpandedToggled, animation: Animation.easeInOut)
		}
	}

	@ViewBuilder
	fileprivate func componentView(with viewStore: ViewStore, index: Int) -> some View {
		let asset = viewStore.container.assets[index]
		Component(
			token: asset,
			isLast: index == nftCount(with: viewStore) - 1,
			isExpanded: viewStore.isExpanded
		)
		.scaleEffect(scale(with: viewStore, index: index))
		.offset(y: offset(with: viewStore, index: index))
		.zIndex(reversedZIndex(count: nftCount(with: viewStore), index: index))
		.transition(.move(edge: .bottom))
		.contentShape(Rectangle())
		.onTapGesture { viewStore.send(.selected(.init(container: viewStore.container, asset: asset))) }
	}

	fileprivate func collapsedHeight(with viewStore: ViewStore) -> CGFloat {
		let headerHeight = rowHeights[Constants.headerIndex] ?? 0
		let collapsedRowsCount = nftCount(with: viewStore)
		let visibleCollapsedRowsHeight: CGFloat = collapsedRowsCount > 1 ? Constants.twoOrMoreCollapsedCardsHeight : Constants.oneCollapsedCardHeight
		return headerHeight + visibleCollapsedRowsHeight
	}

	fileprivate func headerSupplyText(with _: ViewStore) -> String {
		// TODO: remove when API is ready
		L10n.NftList.Header.supplyUnknown

		// TODO: update when API is ready
		/*
		 guard let supply = viewStore.containers.first?.asset.supply else {
		 	return L10n.NftList.Header.supplyUnknown
		 }

		 switch supply {
		 case let .fixed(value):
		 	return NSLocalizedString(L10n.NftList.ownedOfTotal(viewStore.containers.count, Int(value.magnitude)), comment: "Number of NFTs owned of total number")
		 case .mutable:
		 	return NSLocalizedString(L10n.NftList.nftPlural(viewStore.containers.count), comment: "Number of NFTs owned")
		 }
		 */
	}

	fileprivate var headerIconAsset: ImageAsset {
		// TODO: implement depending on the API design
		AssetResource.nft
	}

	fileprivate func nftCount(with viewStore: ViewStore) -> Int {
		viewStore.container.assets.count
	}
}

// MARK: - NonFungibleTokenList.Row.View.Constants
extension NonFungibleTokenList.Row.View {
	fileprivate enum Constants {
		/// header card index
		static let headerIndex: Int = -1

		/// header height
		static let headerHeight: CGFloat = 104

		/// one collapsed visible NFT card height
		static let oneCollapsedCardHeight: CGFloat = 10

		/// two or more visible collapsed NFT cards height
		static let twoOrMoreCollapsedCardsHeight: CGFloat = 20

		/// number of visible NFT cards in collapsed view, excluding header (top) card
		static let cardLimit = 2

		/// default scale for one card
		static let scale: CGFloat = 0.05

		/// offset used in collapsed view for visible cards
		static let visibleCardOffset = -58

		/// offset used in collapsed view for non visible cards
		static let nonVisibleCardOffset = -70
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct Row_Preview: PreviewProvider {
	static var previews: some View {
		NonFungibleTokenList.Row.View(
			store: .init(
				initialState: .previewValue,
				reducer: NonFungibleTokenList.Row()
			)
		)
	}
}

extension NonFungibleTokenList.Row.State {
	public static let previewValue = Self(
		container: .mock1
	)
}
#endif
