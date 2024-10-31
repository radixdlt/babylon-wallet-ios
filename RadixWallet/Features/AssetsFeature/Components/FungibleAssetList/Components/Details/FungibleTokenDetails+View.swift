import ComposableArchitecture
import SwiftUI

extension FungibleTokenDetails.State {
	var detailsHeader: DetailsContainerWithHeaderViewState {
		.init(
			title: resource.metadata.get(\.name, prefetched: ownedFungibleResource?.metadata).map { $0 ?? L10n.Account.PoolUnits.unknownPoolUnitName },
			amount: ownedFungibleResource?.amount.exactAmount?.nominalAmount.formatted(), // FIXME: handle not exact amounts
			currencyWorth: ownedFungibleResource?.amount.exactAmount?.fiatWorth?.currencyFormatted(applyCustomFont: false), // FIXME: handle not exact amounts
			symbol: resource.metadata.get(\.symbol, prefetched: ownedFungibleResource?.metadata)
		)
	}

	var thumbnail: Loadable<Thumbnail.TokenContent> {
		let iconURL = resource.metadata.get(\.iconURL, prefetched: ownedFungibleResource?.metadata)
		return isXRD ? .success(.xrd) : iconURL.map { .other($0) }
	}

	var details: AssetResourceDetailsSection.ViewState {
		.init(
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
	}
}

// MARK: - FungibleTokenDetails.View
extension FungibleTokenDetails {
	struct View: SwiftUI.View {
		let store: StoreOf<FungibleTokenDetails>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				DetailsContainerWithHeaderView(viewState: store.detailsHeader) {
					store.send(.view(.closeButtonTapped))
				} thumbnailView: {
					Thumbnail(token: store.thumbnail.wrappedValue ?? .other(nil), size: .veryLarge)
				} detailsView: {
					VStack(spacing: .medium1) {
						AssetResourceDetailsSection(viewState: store.details)

						HideResource.View(store: store.hideResource)
					}
					.padding(.bottom, .medium1)
				}
				.task { @MainActor in
					await store.send(.view(.task)).finish()
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
