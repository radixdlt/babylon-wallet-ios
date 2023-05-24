import FeaturePrelude

// MARK: - NonFungibleTokenList.Row.View
extension NonFungibleTokenList.Row {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let spacing: CGFloat = .small3 / 2

		private let store: StoreOf<NonFungibleTokenList.Row>

		public init(store: StoreOf<NonFungibleTokenList.Row>) {
			self.store = store
		}
	}
}

extension NonFungibleTokenList.Row.View {
	public var body: some SwiftUI.View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			if viewStore.resource.tokens.isEmpty {
				EmptyView()
			} else {
				StackedViewsLayout(isExpanded: viewStore.isExpanded) {
					rowView(viewStore)
						.zIndex(1000)
					ForEach(
						Array(viewStore.resource.tokens.prefix(viewStore.isExpanded ? viewStore.nftCount - 1 : 6).enumerated()),
						id: \.element
					) { index, item in
						componentView(with: viewStore, asset: item, index: index)
					}
				}
				.padding(.horizontal, .medium3)
			}
		}
	}

	private func rowView(_ viewStore: ViewStoreOf<NonFungibleTokenList.Row>) -> some SwiftUI.View {
		HStack {
			NFTThumbnail(viewStore.resource.iconURL, size: .small)

			VStack(alignment: .leading, spacing: .small2) {
				Text(viewStore.resource.name ?? "")
					.foregroundColor(.app.gray1)
					.textStyle(.secondaryHeader)
				Text("3 of 25,000")
			}

			Spacer()
		}
		.padding(.horizontal, .medium1)
		.padding(.vertical, .large3)
		.background(.app.white)
		.roundedCorners(radius: .small1, corners: viewStore.isExpanded ? .top : .allCorners)
		.tokenRowShadow(!viewStore.isExpanded)
		.onTapGesture {
			viewStore.send(.isExpandedToggled, animation: .easeIn)
		}
	}
}

// MARK: - Private Computed Properties
extension NonFungibleTokenList.Row.View {
	@ViewBuilder
	fileprivate func componentView(
		with viewStore: ViewStoreOf<NonFungibleTokenList.Row>,
		asset: AccountPortfolio.NonFungibleResource.NonFungibleToken,
		index: Int
	) -> some View {
		HStack {
			NFTIDView(
				id: asset.id.toUserFacingString,
				name: asset.name,
				description: asset.description,
				thumbnail: viewStore.isExpanded ? asset.keyImageURL : nil
			)
			if case let .selection(selectedItems) = viewStore.mode {
				CheckmarkView(appearance: .dark, isChecked: selectedItems.contains(asset))
			}
		}
		.padding(.medium1)
		.background(.app.white)
		.bottomRoundedCorners(radius: viewStore.isExpanded ? .zero : .small1)
		.tokenRowShadow(!viewStore.isExpanded)
		.scaleEffect(scale(isExpanded: viewStore.isExpanded, index: index))
		.zIndex(reversedZIndex(count: viewStore.nftCount, index: index))
		.onTapGesture { viewStore.send(.tokenTapped(asset.id)) }
	}

	fileprivate func headerSupplyText(with viewStore: ViewStoreOf<NonFungibleTokenList.Row>) -> String {
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

private extension NonFungibleTokenList.Row.ViewState {
	var nftCount: Int {
		resource.tokens.count
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
		resource: .init(resourceAddress: .init(address: "resource_tdx_c_1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq40v2wv"), tokens: []),
		mode: .normal
	)
}
#endif

// MARK: - StackedViewsLayout
struct StackedViewsLayout: Layout {
	var isExpanded: Bool
	var spacing: CGFloat = 5
	var displacement: CGFloat = 20.0
	var numberOfCards = 3

	static var layoutProperties: LayoutProperties {
		var properties = LayoutProperties()
		properties.stackOrientation = .vertical
		return properties
	}

	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		let container = proposal.replacingUnspecifiedDimensions()
		guard !subviews.isEmpty else {
			return proposal.replacingUnspecifiedDimensions()
		}

		let heights = subviews.map { $0.sizeThatFits(.init(width: container.width, height: nil)).height }
		let height: CGFloat = {
			if !isExpanded {
				return heights[0] + CGFloat(numberOfCards - 1) * displacement
			} else {
				return heights.reduce(0.0, +) + spacing * CGFloat(subviews.count - 1)
			}
		}()
		return .init(width: container.width, height: height)
	}

	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		let container = proposal.replacingUnspecifiedDimensions()
		var offset: CGFloat = 0
		for (index, subview) in subviews.enumerated() {
			let place = CGPoint(x: bounds.minX, y: bounds.minY + offset)
			subview.place(at: place, proposal: .init(width: container.width, height: nil))

			if isExpanded {
				let subviewSize = subview.sizeThatFits(.init(width: container.width, height: nil))
				offset += subviewSize.height + spacing
			} else {
				// The rest of the cards that go over `numberOfCards` will go behind the last card.
				if index < numberOfCards - 1 {
					offset += displacement
				}
			}
		}
	}
}
