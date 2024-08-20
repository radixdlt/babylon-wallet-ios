import SwiftUI

// MARK: - HiddenAssets.View
extension HiddenAssets {
	public struct View: SwiftUI.View {
		public let store: StoreOf<HiddenAssets>

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					LazyVStack(alignment: .leading, spacing: .large3) {
						Text(L10n.HiddenAssets.text)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)

						header(L10n.HiddenAssets.fungibles)
						fungibles

						header(L10n.HiddenAssets.nonFungibles)
						nonFungibles

						header(L10n.HiddenAssets.poolUnits)
						poolUnits
					}
					.padding(.medium3)
				}
				.background(Color.app.gray5)
				.radixToolbar(title: L10n.HiddenAssets.title)
				.task {
					store.send(.view(.task))
				}
				.alert(store: store.scope(state: \.$destination.unhideAlert, action: \.destination.unhideAlert))
			}
		}

		private func header(_ value: String) -> some SwiftUI.View {
			Text(value)
				.textStyle(.secondaryHeader)
				.foregroundColor(.app.gray2)
		}

		@ViewBuilder
		private var fungibles: some SwiftUI.View {
			if store.fungible.isEmpty {
				empty
			} else {
				VStack(spacing: .medium3) {
					ForEachStatic(store.fungible) { resource in
						Card {
							PlainListRow(viewState: .init(
								rowCoreViewState: .init(context: .hiddenAsset, title: resource.fungibleResourceName),
								accessory: { unhideButton(asset: .fungible(resource.resourceAddress)) },
								icon: { Thumbnail(.token(.other), url: resource.metadata.iconURL) }
							))
						}
					}
				}
			}
		}

		@ViewBuilder
		private var nonFungibles: some SwiftUI.View {
			if store.nonFungible.isEmpty {
				empty
			} else {
				VStack(spacing: .medium3) {
					ForEachStatic(store.nonFungible) { details in
						Card {
							PlainListRow(viewState: .init(
								rowCoreViewState: details.rowCoreViewState,
								accessory: { unhideButton(asset: .nonFungible(details.token.id)) },
								icon: { Thumbnail(.nft, url: details.resource.metadata.iconURL) }
							))
						}
					}
				}
			}
		}

		@ViewBuilder
		private var poolUnits: some SwiftUI.View {
			if store.poolUnit.isEmpty {
				empty
			} else {
				VStack(spacing: .medium3) {
					ForEachStatic(store.poolUnit) { poolUnit in
						Card {
							PlainListRow(viewState: .init(
								rowCoreViewState: poolUnit.rowCoreViewState,
								accessory: { unhideButton(asset: .poolUnit(poolUnit.details.address)) },
								icon: { Thumbnail(.poolUnit, url: poolUnit.resource.metadata.iconURL) }
							))
						}
					}
				}
			}
		}

		private func unhideButton(asset: AssetAddress) -> some SwiftUI.View {
			Button(L10n.HiddenAssets.unhide) {
				store.send(.view(.unhideTapped(asset)))
			}
			.buttonStyle(.secondaryRectangular(shouldExpand: false))
		}

		private var empty: some SwiftUI.View {
			ZStack {
				PlainListRow(viewState: .init(
					rowCoreViewState: .init(context: .hiddenAsset, title: "dummy"),
					accessory: { unhideButton(asset: .fungible(.mainnetXRD)) },
					icon: { Thumbnail(.token(.other), url: nil) }
				))
				.hidden()

				Text(L10n.Common.none)
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray2)
			}
			.background(Color.app.gray4)
			.clipShape(RoundedRectangle(cornerRadius: .medium3))
		}
	}
}

private extension HiddenAssets.State.NonFungibleDetails {
	var rowCoreViewState: PlainListRowCore.ViewState {
		.init(
			context: .hiddenAsset,
			title: resource.metadata.name ?? token.id.resourceAddress.formatted(),
			subtitle: token.data?.name ?? token.id.localID.formatted()
		)
	}
}

private extension HiddenAssets.State.PoolUnitDetails {
	var rowCoreViewState: PlainListRowCore.ViewState {
		.init(context: .hiddenAsset, title: "-", subtitle: details.dAppName ?? "-")
	}
}
