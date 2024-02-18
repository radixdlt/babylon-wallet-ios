import ComposableArchitecture
import SwiftUI

// MARK: - NonFungibleTokenList.Row.View
extension NonFungibleAssetList.Row {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleAssetList.Row>

		public init(store: StoreOf<NonFungibleAssetList.Row>) {
			self.store = store
		}
	}
}

extension NonFungibleAssetList.Row.View {
	public var body: some SwiftUI.View {
		WithViewStore(
			store,
			observe: identity,
			send: NonFungibleAssetList.Row.Action.view
		) { viewStore in
			Section {
				rowView(viewStore)
					.rowStyle()

				if viewStore.isExpanded {
					ForEach(
						Array(
							viewStore.tokens.flatMap(identity).enumerated()
						),
						id: \.offset
					) { index, item in
						componentView(with: viewStore, asset: item, index: index)
							.rowStyle()
							.onAppear {
								viewStore.send(.onTokenDidAppear(index: index))
							}
					}
				}
			}
			.listSectionSeparator(.hidden)
		}
	}

	private func rowView(_ viewStore: ViewStoreOf<NonFungibleAssetList.Row>) -> some SwiftUI.View {
		HStack(spacing: .small1) {
			Thumbnail(.nft, url: viewStore.resource.metadata.iconURL, size: .small)

			VStack(alignment: .leading, spacing: .small2) {
				if let title = viewStore.resource.metadata.title {
					Text(title)
						.foregroundColor(.app.gray1)
						.lineSpacing(-4)
						.textStyle(.secondaryHeader)
				}

				Text("\(viewStore.resource.nonFungibleIdsCount)")
					.font(.app.body2HighImportance)
					.foregroundColor(.app.gray2)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.horizontal, .medium1)
		.frame(height: headerHeight)
		.background(.app.white)
		.onTapGesture {
			viewStore.send(.isExpandedToggled, animation: .easeInOut)
		}
	}

	private var headerHeight: CGFloat { HitTargetSize.small.frame.height + 2 * .medium1 }
}

// MARK: - Private Computed Properties
extension NonFungibleAssetList.Row.View {
	@ViewBuilder
	fileprivate func componentView(
		with viewStore: ViewStoreOf<NonFungibleAssetList.Row>,
		asset: Loadable<OnLedgerEntity.NonFungibleToken>,
		index: Int
	) -> some View {
		loadable(asset) {
			/// Placeholder Loading view
			VStack(spacing: .medium3) {
				shimmeringLoadingView(height: .imagePlaceholderHeight)
				shimmeringLoadingView(height: .medium1)
				shimmeringLoadingView(height: .medium1)
			}
			.padding(.medium1)
			.frame(minHeight: headerHeight)
		} successContent: { asset in
			let isDisabled = viewStore.disabled.contains(asset.id)
			VStack(spacing: .zero) {
				Divider()
					.frame(height: .small3)
					.overlay(.app.gray5)

				HStack {
					NFTIDView(
						id: asset.id.localId().toUserFacingString(),
						name: asset.data?.name,
						thumbnail: asset.data?.keyImageURL
					)
					if let selectedAssets = viewStore.selectedAssets {
						CheckmarkView(appearance: .dark, isChecked: selectedAssets.contains(asset))
					}
				}
				.opacity(isDisabled ? 0.35 : 1)
				.padding(.medium1)
				.frame(minHeight: headerHeight)
				.background(.app.white)
			}
			.onTapGesture { viewStore.send(.assetTapped(asset)) }
		}
	}
}
