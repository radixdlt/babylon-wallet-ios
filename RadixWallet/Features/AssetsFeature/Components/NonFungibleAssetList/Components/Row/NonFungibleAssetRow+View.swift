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
		Button {
			viewStore.send(.isExpandedToggled)
		} label: {
			HStack(spacing: .zero) {
				Thumbnail(.nft, url: viewStore.resource.metadata.iconURL, size: .small)

				VStack(alignment: .leading, spacing: .small2) {
					if let title = viewStore.resource.metadata.name {
						Text(title)
							.foregroundColor(.app.gray1)
							.lineSpacing(-4)
							.textStyle(.secondaryHeader)
					}

					Text("\(viewStore.resource.nonFungibleIdsCount)")
						.font(.app.body2HighImportance)
						.foregroundColor(.app.gray2)
				}
				.padding(.leading, .small1)

				Spacer()
			}
			.padding(.horizontal, .medium1)
			.padding(.top, .large3)
			.padding(.bottom, .medium1)
			.background(.app.white)
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
					.frame(height: .assetsDividerHeight)
					.overlay(.app.gray5)

				HStack {
					NFTIDView(
						id: asset.id.nonFungibleLocalId.formatted(),
						name: asset.data?.name,
						thumbnail: asset.data?.keyImageURL
					)
					if let selectedAssets = viewStore.selectedAssets {
						CheckmarkView(appearance: .dark, isChecked: selectedAssets.contains(asset))
					}
				}
				.opacity(isDisabled ? 0.35 : 1)
				.padding(.vertical, .medium1)
				.padding(.horizontal, .medium3)
				.frame(minHeight: headerHeight)
				.background(.app.white)
			}
			.onTapGesture { viewStore.send(.assetTapped(asset)) }
		}
	}
}
