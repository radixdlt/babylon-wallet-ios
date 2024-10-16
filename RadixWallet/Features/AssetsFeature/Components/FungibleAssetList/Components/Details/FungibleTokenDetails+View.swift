import ComposableArchitecture
import SwiftUI

extension FungibleTokenDetails.State {
	var viewState: FungibleTokenDetails.ViewState {
		.init(
			detailsHeader: detailsHeader,
			thumbnail: {
				let iconURL = resource.metadata.get(\.iconURL, prefetched: ownedFungibleResource?.metadata)
				return isXRD ? .success(.xrd) : iconURL.map { .other($0) }
			}(),
			details: .init(
				description: resource.metadata.get(\.description, prefetched: ownedFungibleResource?.metadata),
				infoUrl: resource.metadata.infoURL,
				resourceAddress: resourceAddress,
				isXRD: isXRD,
				validatorAddress: nil,
				resourceName: resource.metadata.name,
				currentSupply: resource.totalSupply.map { $0?.formatted() ?? L10n.AssetDetails.supplyUnkown },
				divisibility: resource.divisibility,
				arbitraryDataFields: resource.metadata.arbitraryItems.asDataFields,
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
			amount: ownedFungibleResource?.amount.nominalAmount.formatted(),
			currencyWorth: ownedFungibleResource?.amount.fiatWorth?.currencyFormatted(applyCustomFont: false),
			symbol: resource.metadata.get(\.symbol, prefetched: ownedFungibleResource?.metadata)
		)
	}
}

// MARK: - FungibleTokenDetails.View
extension FungibleTokenDetails {
	struct ViewState: Equatable {
		let detailsHeader: DetailsContainerWithHeaderViewState
		let thumbnail: Loadable<Thumbnail.TokenContent>
		let details: AssetResourceDetailsSection.ViewState
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<FungibleTokenDetails>

		init(store: StoreOf<FungibleTokenDetails>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				DetailsContainerWithHeaderView(viewState: viewStore.detailsHeader) {
					viewStore.send(.closeButtonTapped)
				} thumbnailView: {
					Thumbnail(token: viewStore.thumbnail.wrappedValue ?? .other(nil), size: .veryLarge)
				} detailsView: {
					VStack(spacing: .medium1) {
						AssetResourceDetailsSection(viewState: viewStore.details)

						HideResource.View(store: store.hideResource)
					}
					.padding(.bottom, .medium1)
				}
				.task { @MainActor in
					await viewStore.send(.task).finish()
				}
			}
		}
	}
}

private extension StoreOf<FungibleTokenDetails> {
	var hideResource: StoreOf<HideResource> {
		scope(state: \.hideResource, action: \.child.hideResource)
	}
}
