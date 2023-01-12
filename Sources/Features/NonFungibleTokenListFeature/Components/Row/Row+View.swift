import Asset
import FeaturePrelude

// MARK: - NonFungibleTokenList.Row.View
public extension NonFungibleTokenList.Row {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		@SwiftUI.State private var expandedHeight: CGFloat = .zero
		@SwiftUI.State private var rowHeights: [Int: CGFloat] = [:] {
			didSet {
				expandedHeight = rowHeights.map(\.value).reduce(0, +)
			}
		}

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

public extension NonFungibleTokenList.Row.View {
	var body: some View {
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

// MARK: - NonFungibleTokenList.Row.View.ViewStore
private extension NonFungibleTokenList.Row.View {
	typealias ViewStore = ComposableArchitecture.ViewStore<NonFungibleTokenList.Row.View.ViewState, NonFungibleTokenList.Row.Action.ViewAction>
}

// MARK: - NonFungibleTokenList.Row.View.ViewState
extension NonFungibleTokenList.Row.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		let container: NonFungibleTokenContainer
		var isExpanded: Bool

		init(state: NonFungibleTokenList.Row.State) {
			container = state.container
			isExpanded = state.isExpanded
		}
	}
}

// MARK: - Private Methods
private extension NonFungibleTokenList.Row.View {
	func scale(with viewStore: ViewStore, index: Int) -> CGFloat {
		if index >= Constants.cardLimit {
			return viewStore.isExpanded ? 1 : 1 - (CGFloat(Constants.cardLimit) * Constants.scale)
		} else {
			return viewStore.isExpanded ? 1 : 1 - (CGFloat(index + 1) * Constants.scale)
		}
	}

	func offset(with viewStore: ViewStore, index: Int) -> CGFloat {
		if index >= Constants.cardLimit {
			return viewStore.isExpanded ? 0 : CGFloat((index + 1) * Constants.nonVisibleCardOffset)
		} else {
			return viewStore.isExpanded ? 0 : CGFloat((index + 1) * Constants.visibleCardOffset)
		}
	}

	func reversedZIndex(count: Int, index: Int) -> Double {
		Double(count - index)
	}
}

// MARK: - Private Computed Properties
private extension NonFungibleTokenList.Row.View {
	func headerView(with viewStore: ViewStore, index: Int) -> some View {
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
	func componentView(with viewStore: ViewStore, index: Int) -> some View {
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

	func collapsedHeight(with viewStore: ViewStore) -> CGFloat {
		let headerHeight = rowHeights[Constants.headerIndex] ?? 0
		let collapsedRowsCount = nftCount(with: viewStore)
		let visibleCollapsedRowsHeight: CGFloat = collapsedRowsCount > 1 ? Constants.twoOrMoreCollapsedCardsHeight : Constants.oneCollapsedCardHeight
		return headerHeight + visibleCollapsedRowsHeight
	}

	func headerSupplyText(with _: ViewStore) -> String {
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

	var headerIconAsset: ImageAsset {
		// TODO: implement depending on the API design
		AssetResource.nft
	}

	func nftCount(with viewStore: ViewStore) -> Int {
		viewStore.container.assets.count
	}
}

// MARK: - NonFungibleTokenList.Row.View.Constants
private extension NonFungibleTokenList.Row.View {
	enum Constants {
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

// MARK: - Row_Preview
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
#endif
