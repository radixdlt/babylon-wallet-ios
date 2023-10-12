import EngineKit
import FeaturePrelude

extension FungibleTokenDetails.State {
	var viewState: FungibleTokenDetails.ViewState {
		.init(
			detailsHeader: detailsHeader,
			thumbnail: {
				let iconURL = resource.metadata.get(\.iconURL, prefetched: ownedFungibleResource?.metadata)
				return isXRD ? .success(.xrd) : iconURL.map { .known($0) }
			}(),
			details: .init(
				description: resource.metadata.get(\.description, prefetched: ownedFungibleResource?.metadata),
				resourceAddress: resourceAddress,
				isXRD: isXRD,
				validatorAddress: nil,
				resourceName: nil,
				currentSupply: resource.totalSupply.map { $0?.formatted() ?? L10n.AssetDetails.supplyUnkown },
				behaviors: resource.behaviors,
				tags: {
					let tags = resource.metadata.get(\.tags, prefetched: ownedFungibleResource?.metadata)
					return isXRD ? tags.map { $0 + [.officialRadix] } : tags
				}()
			)
		)
	}

	var detailsHeader: DetailsContainerWithHeaderViewState {
		.init(
			title: resource.metadata.get(\.name, prefetched: ownedFungibleResource?.metadata).map { $0 ?? L10n.Account.PoolUnits.unknownPoolUnitName },
			amount: ownedFungibleResource?.amount.formatted(),
			symbol: resource.metadata.get(\.symbol, prefetched: ownedFungibleResource?.metadata)
		)
	}
}

// MARK: - FungibleTokenDetails.View
extension FungibleTokenDetails {
	public struct ViewState: Equatable {
		let detailsHeader: DetailsContainerWithHeaderViewState
		let thumbnail: Loadable<TokenThumbnail.Content>
		let details: AssetResourceDetailsSection.ViewState
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleTokenDetails>

		public init(store: StoreOf<FungibleTokenDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				DetailsContainerWithHeaderView(viewState: viewStore.detailsHeader) {
					viewStore.send(.closeButtonTapped)
				} thumbnailView: {
					TokenThumbnail(viewStore.thumbnail.wrappedValue ?? .unknown, size: .veryLarge)
				} detailsView: {
					AssetResourceDetailsSection(viewState: viewStore.details)
						.padding(.bottom, .medium1)
				}
				.task { @MainActor in
					await viewStore.send(.task).finish()
				}
			}
		}
	}
}
