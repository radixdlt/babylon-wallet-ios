import EngineKit
import FeaturePrelude

extension FungibleTokenDetails.State {
	var viewState: FungibleTokenDetails.ViewState {
		.init(
			detailsHeader: detailsHeader,
			thumbnail: {
				let iconURL = prefetchedPortfolioResource.map { .success($0.metadata.iconURL) } ?? resource.resourceMetadata.iconURL
				return isXRD ? .success(.xrd) : iconURL.map { .known($0) }
			}(),
			details: .init(
				description: resource.resourceMetadata.description,
				resourceAddress: resourceAddress,
				isXRD: isXRD,
				validatorAddress: nil,
				resourceName: nil,
				currentSupply: resource.totalSupply.map { $0?.format() }, // FIXME: Check which format
				behaviors: resource.behaviors,
				tags: {
					let tags = prefetchedPortfolioResource.map { .success($0.metadata.tags) } ?? resource.resourceMetadata.tags
					return isXRD ? tags.map { $0 + [.officialRadix] } : tags
				}()
			)
		)
	}

	var detailsHeader: DetailsContainerWithHeaderViewState {
		.init(
			title: prefetchedPortfolioResource?.metadata.name ?? L10n.Account.PoolUnits.unknownPoolUnitName,
			amount: prefetchedPortfolioResource?.amount.format(),
			symbol: prefetchedPortfolioResource?.metadata.symbol
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
					TokenThumbnail(viewStore.thumbnail.wrappedValue ?? .unknown, size: .veryLarge)
				} detailsView: {
					AssetResourceDetailsSection(viewState: viewStore.details)
						.padding(.bottom, .medium1)
				} closeButtonAction: {
					viewStore.send(.closeButtonTapped)
				}
				.task { @MainActor in
					await viewStore.send(.task).finish()
				}
			}
		}
	}
}
