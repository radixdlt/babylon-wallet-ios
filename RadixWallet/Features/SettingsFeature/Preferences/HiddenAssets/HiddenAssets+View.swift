import SwiftUI

// MARK: - HiddenAssets.View
extension HiddenAssets {
	public struct View: SwiftUI.View {
		public let store: StoreOf<HiddenAssets>

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					LazyVStack(alignment: .leading, spacing: .large3) {
						Text("You have hidden the following assets. While hidden, you will not see these in any of your Accounts.")
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)

						header("Tokens")
						fungible

						header("NFTs")
						nonFungible

						header("Pool Units")
						poolUnit
					}
					.padding(.medium3)
				}
				.background(Color.app.gray5)
				.radixToolbar(title: "Hidden Assets")
			}
			.task {
				store.send(.view(.task))
			}
			.alert(store: store.scope(state: \.$destination.unhideAlert, action: \.destination.unhideAlert))
		}

		private func header(_ value: String) -> some SwiftUI.View {
			Text(value)
				.textStyle(.secondaryHeader)
				.foregroundColor(.app.gray2)
		}

		@ViewBuilder
		private var fungible: some SwiftUI.View {
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
		private var nonFungible: some SwiftUI.View {
			if store.nonFungible.isEmpty {
				empty
			} else {
				VStack(spacing: .medium3) {
					ForEachStatic(store.nonFungible) { token in
						Card {
							PlainListRow(viewState: .init(
								rowCoreViewState: token.rowCoreViewState,
								accessory: { unhideButton(asset: .nonFungible(token.id)) },
								icon: { Thumbnail(.nft, url: token.data?.keyImageURL) }
							))
						}
					}
				}
			}
		}

		@ViewBuilder
		private var poolUnit: some SwiftUI.View {
			if store.poolUnit.isEmpty {
				empty
			} else {
				VStack(spacing: .medium3) {
					ForEachStatic(store.poolUnit) { resource in
						Card {
							PlainListRow(viewState: .init(
								rowCoreViewState: .init(context: .hiddenAsset, title: resource.metadata.name ?? "Pool Unit"),
								accessory: { unhideButton(asset: .poolUnit(resource.address)) },
								icon: { Thumbnail(.poolUnit, url: resource.metadata.iconURL) }
							))
						}
					}
				}
			}
		}

		private func unhideButton(asset: AssetAddress) -> some SwiftUI.View {
			Button("Unhide") {
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

				Text("None")
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray2)
			}
			.background(Color.app.gray4)
			.clipShape(RoundedRectangle(cornerRadius: .medium3))
		}
	}
}

private extension OnLedgerEntity.NonFungibleToken {
	var rowCoreViewState: PlainListRowCore.ViewState {
		.init(context: .hiddenAsset, title: data?.name, subtitle: id.nonFungibleLocalId.formatted())
	}
}
