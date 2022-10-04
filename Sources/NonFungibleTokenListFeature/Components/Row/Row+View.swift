import Asset
import Common
import ComposableArchitecture
import SwiftUI

// MARK: - NonFungibleTokenList.Row.View
public extension NonFungibleTokenList.Row {
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<RowState, Action>
		private let store: Store

		@State private var expandedHeight: CGFloat = .zero
		@State private var rowHeights: [Int: CGFloat] = [:] {
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
			store.scope(
				state: ViewState.init,
				action: NonFungibleTokenList.Row.Action.init
			)
		) { viewStore in
			VStack(spacing: 1) {
				ForEach(-1 ..< viewStore.containers.count) { index in
					Group {
						switch index {
						case -1:
							Header(
								name: headerNameText,
								supply: headerSupplyText(with: viewStore),
								imageURL: headerIconURL,
								isExpanded: viewStore.isExpanded
							)
							.zIndex(reversedZIndex(count: viewStore.containers.count, index: index))
							.onTapGesture {
								viewStore.send(.toggleIsExpanded, animation: Animation.easeInOut)
							}
						default:
							Component(
								container: viewStore.containers[index],
								isLast: index == viewStore.containers.count - 1,
								isExpanded: viewStore.isExpanded
							)
							.scaleEffect(scale(with: viewStore, index: index))
							.offset(y: offset(with: viewStore, index: index))
							.zIndex(reversedZIndex(count: viewStore.containers.count, index: index))
							.transition(.move(edge: .bottom))
						}
					}
					.onSizeChanged(ReferenceView.self) { size in
						rowHeights[index] = size.height
					}
				}
				.padding([.leading, .trailing], 24)
			}
			.frame(height: viewStore.isExpanded ? expandedHeight : collapsedHeight(with: viewStore), alignment: .top)
		}
	}
}

// MARK: - NonFungibleTokenList.Row.View.ViewStore
private extension NonFungibleTokenList.Row.View {
	typealias ViewStore = ComposableArchitecture.ViewStore<NonFungibleTokenList.Row.View.ViewState, NonFungibleTokenList.Row.View.ViewAction>
}

// MARK: - NonFungibleTokenList.Row.View.ViewAction
extension NonFungibleTokenList.Row.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case toggleIsExpanded
	}
}

extension NonFungibleTokenList.Row.Action {
	init(action: NonFungibleTokenList.Row.View.ViewAction) {
		switch action {
		case .toggleIsExpanded:
			self = .internal(.user(.toggleIsExpanded))
		}
	}
}

// MARK: - NonFungibleTokenList.Row.View.ViewState
extension NonFungibleTokenList.Row.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		let containers: [NonFungibleTokenContainer]
		var isExpanded: Bool

		init(
			state: NonFungibleTokenList.Row.RowState
		) {
			containers = state.containers
			isExpanded = state.isExpanded
		}
	}
}

// MARK: - Private Methods
private extension NonFungibleTokenList.Row.View {
	func scale(with viewStore: ViewStore, index: Int) -> CGFloat {
		if index > Constants.cardLimit {
			return viewStore.isExpanded ? 1 : 1 - (CGFloat(Constants.cardLimit + 1) * Constants.scale)
		} else {
			return viewStore.isExpanded ? 1 : 1 - (CGFloat(index + 1) * Constants.scale)
		}
	}

	func offset(with viewStore: ViewStore, index: Int) -> CGFloat {
		if index > Constants.cardLimit {
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
	func collapsedHeight(with viewStore: ViewStore) -> CGFloat {
		let firstRowHeight = rowHeights[0] ?? 0
		let additionalRowsCount = viewStore.containers.count - 1
		let offsetHeight: CGFloat = additionalRowsCount > 1 ? 20 : 10
		return firstRowHeight + offsetHeight
	}

	var headerNameText: String {
		// TODO: implement depending on the API design
		"Some NFT"
	}

	func headerSupplyText(with viewStore: ViewStore) -> String {
		guard let supply = viewStore.containers.first?.asset.supply else {
			return L10n.NftList.Header.supplyUnknown
		}

		switch supply {
		case let .fixed(value):
			return NSLocalizedString(L10n.NftList.ownedOfTotal(viewStore.containers.count, Int(value.magnitude)), comment: "Number of NFTs owned of total number")
		case .mutable:
			return NSLocalizedString(L10n.NftList.nftPlural(viewStore.containers.count), comment: "Number of NFTs owned")
		}
	}

	var headerIconURL: String? {
		// TODO: implement depending on the API design
		"nft-logo"
	}
}

// MARK: - NonFungibleTokenList.Row.View.Constants
private extension NonFungibleTokenList.Row.View {
	enum Constants {
		/// number of visible NFT cards in collapsed view, excluding header (top) card
		static let cardLimit = 1

		/// default scale for one card
		static let scale: CGFloat = 0.05

		/// offset used in collapsed view
		static let visibleCardOffset = -58
		static let nonVisibleCardOffset = -70
	}
}

// MARK: - Row_Preview
struct Row_Preview: PreviewProvider {
	static var previews: some View {
		NonFungibleTokenList.Row.View(
			store: .init(
				initialState: .init(containers: [.init(asset: .mock, metadata: nil)]),
				reducer: NonFungibleTokenList.Row.reducer,
				environment: .init()
			)
		)
	}
}
