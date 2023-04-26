import FeaturePrelude

// MARK: - NonFungibleTokenList.Row.View
extension NonFungibleTokenList.Row {
	public struct ViewState: Equatable {
		let resource: AccountPortfolio.NonFungibleResource
		let isExpanded: Bool

		init(state: NonFungibleTokenList.Row.State) {
			self.resource = state.token
			self.isExpanded = state.isExpanded
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let spacing: CGFloat = .small3 / 2

		private let store: StoreOf<NonFungibleTokenList.Row>

		@SwiftUI.State private var expandedHeight: CGFloat = .zero
		@SwiftUI.State private var rowHeights: [Int: CGFloat] = [:] {
			didSet {
				expandedHeight = rowHeights.map(\.value).reduce(0, +) + CGFloat(max(rowHeights.count - 1, 0)) * spacing
			}
		}

		public init(store: StoreOf<NonFungibleTokenList.Row>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: ViewState.init, send: { .view($0) }) { viewStore in
				VStack(spacing: spacing) {
					if viewStore.resource.tokens.isEmpty {
						EmptyView()
					} else {
						// TODO: There is a performance issue when multiple items are involved, all of the expanded views seems to be actually loaded from the begining.
						ForEach(Constants.headerIndex ..< viewStore.nftCount, id: \.self) { index in
							Group {
								switch index {
								case -1:
									headerView(with: viewStore, index: index)
								case 0 ..< Constants.cardLimit:
									componentView(with: viewStore, index: index)
								default:
									if viewStore.isExpanded {
										componentView(with: viewStore, index: index)
									}
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

// MARK: - Private Computed Properties
extension NonFungibleTokenList.Row.View {
	fileprivate func headerView(with viewStore: ViewStoreOf<NonFungibleTokenList.Row>, index: Int) -> some View {
		Header(
			name: viewStore.resource.name ?? "",
			thumbnail: viewStore.resource.iconURL,
			isExpanded: viewStore.isExpanded
		)
		.zIndex(reversedZIndex(count: viewStore.nftCount, index: index))
		.onTapGesture {
			viewStore.send(.isExpandedToggled, animation: .easeInOut)
		}
	}

	@ViewBuilder
	fileprivate func componentView(with viewStore: ViewStoreOf<NonFungibleTokenList.Row>, index: Int) -> some View {
		let asset = viewStore.resource.tokens[index]
		NFTIDView(
			id: asset.id.toUserFacingString,
			thumbnail: asset.keyImageURL,
			isLast: index == viewStore.nftCount - 1,
			isExpanded: viewStore.isExpanded
		)
		.scaleEffect(scale(isExpanded: viewStore.isExpanded, index: index))
		.offset(y: offset(isExpanded: viewStore.isExpanded, index: index))
		.zIndex(reversedZIndex(count: viewStore.nftCount, index: index))
		.transition(.move(edge: .bottom))
		.contentShape(Rectangle())
		.onTapGesture { viewStore.send(.selected(.init(resource: viewStore.resource, nftID: asset.id))) }
	}

	fileprivate func collapsedHeight(with viewStore: ViewStoreOf<NonFungibleTokenList.Row>) -> CGFloat {
		let headerHeight = rowHeights[Constants.headerIndex, default: 0]
		let collapsedRowsCount = viewStore.nftCount
		let visibleCollapsedRowsHeight = collapsedRowsCount > 1 ? Constants.twoOrMoreCollapsedCardsHeight : Constants.oneCollapsedCardHeight
		let totalSpacing = CGFloat(max(min(rowHeights.count - 1, Constants.cardLimit), 0)) * spacing

		return headerHeight + visibleCollapsedRowsHeight + totalSpacing
	}

	fileprivate func headerSupplyText(with _: ViewStoreOf<NonFungibleTokenList.Row>) -> String {
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
}

private extension NonFungibleTokenList.Row.ViewState {
	var nftCount: Int {
		resource.tokens.count
	}

	func reversedZIndex(index: Int) -> Double {
		Double(nftCount - index)
	}
}

private extension NonFungibleTokenList.Row.View {
	func reversedZIndex(count: Int, index: Int) -> Double {
		Double(count - index)
	}

	func scale(isExpanded: Bool, index: Int) -> CGFloat {
		if isExpanded {
			return 1
		} else {
			return 1 - CGFloat(min(index + 1, Constants.cardLimit)) * Constants.scale
		}
	}

	func offset(isExpanded: Bool, index: Int) -> CGFloat {
		if isExpanded {
			return 0
		} else {
			let offset = index >= Constants.cardLimit ? Constants.nonVisibleCardOffset : Constants.visibleCardOffset
			return CGFloat((index + 1) * offset)
		}
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

extension AccountPortfolio.NonFungibleResource.NonFungibleToken.ID {
	var toUserFacingString: String {
		// Just a safety guard. Each NFT Id should be of format <prefix>value<suffix>
		guard rawValue.count >= 3 else {
			loggerGlobal.warning("Invalid nft id: \(rawValue)")
			return rawValue
		}
		// Nothing fancy, just remove the prefix and suffix.
		return String(rawValue.dropLast(1).dropFirst())
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct NonFungibleRow_Preview: PreviewProvider {
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
		token: .init(resourceAddress: .init(address: "some"), tokens: [])
	)
}
#endif
