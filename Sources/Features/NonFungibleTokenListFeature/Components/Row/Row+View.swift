import Asset
import Common
import ComposableArchitecture
import SwiftUI

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
			VStack(spacing: 1) {
				ForEach(-1 ..< viewStore.containers.count) { index in
					Group {
						switch index {
						case -1:
							Header(
								name: headerNameText,
								supply: headerSupplyText(with: viewStore),
								iconAsset: headerIconAsset,
								isExpanded: viewStore.isExpanded
							)
							.zIndex(reversedZIndex(count: viewStore.containers.count, index: index))
							.onTapGesture {
								viewStore.send(.isExpandedToggled, animation: Animation.easeInOut)
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
				.padding(.horizontal, .medium3)
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
		let containers: [NonFungibleTokenContainer]
		var isExpanded: Bool

		init(state: NonFungibleTokenList.Row.State) {
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
		AssetResource.nftLogo
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

#if DEBUG

// MARK: - Row_Preview
struct Row_Preview: PreviewProvider {
	static var previews: some View {
		NonFungibleTokenList.Row.View(
			store: .init(
				initialState: .init(
					containers: [
						.init(
							owner: try! .init(address: "owner_address"),
							asset: NonFungibleToken.mock1,
							metadata: nil
						),
					]
				),
				reducer: NonFungibleTokenList.Row()
			)
		)
	}
}
#endif
