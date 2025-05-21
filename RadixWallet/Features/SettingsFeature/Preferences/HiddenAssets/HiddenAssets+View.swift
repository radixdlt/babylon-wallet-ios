import SwiftUI

// MARK: - HiddenAssets.View
extension HiddenAssets {
	struct View: SwiftUI.View {
		let store: StoreOf<HiddenAssets>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					LazyVStack(alignment: .leading, spacing: .large3) {
						Text(L10n.HiddenAssets.text)
							.textStyle(.body1HighImportance)
							.foregroundColor(.secondaryText)

						header(L10n.HiddenAssets.fungibles)
						fungibles

						header(L10n.HiddenAssets.nonFungibles)
						nonFungibles

						header(L10n.HiddenAssets.poolUnits)
						poolUnits
					}
					.padding(.medium3)
				}
				.background(.secondaryBackground)
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
				.foregroundColor(.secondaryText)
		}

		@ViewBuilder
		private var fungibles: some SwiftUI.View {
			if store.fungible.isEmpty {
				emptyState
			} else {
				VStack(spacing: .medium3) {
					ForEachStatic(store.fungible) { resource in
						Card {
							AssetRow(
								name: resource.fungibleResourceName,
								address: .resource(resource.resourceAddress),
								type: .token(.other),
								url: resource.metadata.iconURL,
								accessory: { unhideButton(resource: .fungible(resource.resourceAddress)) }
							)
						}
					}
				}
			}
		}

		@ViewBuilder
		private var nonFungibles: some SwiftUI.View {
			if store.nonFungible.isEmpty {
				emptyState
			} else {
				VStack(spacing: .medium3) {
					ForEachStatic(store.nonFungible) { resource in
						Card {
							AssetRow(
								name: resource.metadata.name,
								address: .resource(resource.resourceAddress),
								type: .nft,
								url: resource.metadata.iconURL,
								accessory: { unhideButton(resource: .nonFungible(resource.resourceAddress)) }
							)
						}
					}
				}
			}
		}

		@ViewBuilder
		private var poolUnits: some SwiftUI.View {
			if store.poolUnit.isEmpty {
				emptyState
			} else {
				VStack(spacing: .medium3) {
					ForEachStatic(store.poolUnit) { poolUnit in
						Card {
							AssetRow(
								name: poolUnit.resource.fungibleResourceName,
								address: .resourcePool(poolUnit.details.address),
								type: .poolUnit,
								url: poolUnit.resource.metadata.iconURL,
								accessory: { unhideButton(resource: .poolUnit(poolUnit.details.address)) }
							)
						}
					}
				}
			}
		}

		private func unhideButton(resource: ResourceIdentifier) -> some SwiftUI.View {
			Button(L10n.HiddenAssets.unhide) {
				store.send(.view(.unhideTapped(resource)))
			}
			.buttonStyle(.secondaryRectangular(shouldExpand: false))
		}

		private var emptyState: some SwiftUI.View {
			ZStack {
				AssetRow(name: "dummy", address: .resource(.mainnetXRD), type: .token(.other), url: nil, accessory: { unhideButton(resource: .fungible(.mainnetXRD)) })
					.hidden()

				Text(L10n.Common.none)
					.textStyle(.secondaryHeader)
					.foregroundColor(.secondaryText)
			}
			.background(.tertiaryBackground)
			.clipShape(RoundedRectangle(cornerRadius: .medium3))
		}
	}
}
