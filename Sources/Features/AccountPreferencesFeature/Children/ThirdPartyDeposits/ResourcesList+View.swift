import EngineKit
import FeaturePrelude

extension ResourcesList.State {
	var viewState: ResourcesList.ViewState {
		.init(
			addresses: addresses
		)
	}
}

extension ResourcesList {
	public struct ViewState: Equatable {
		let addresses: Set<DepositAddress>
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<ResourcesList>
		init(store: StoreOf<ResourcesList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				VStack(spacing: .medium1) {
					if !viewStore.addresses.isEmpty {
						List {
							ForEach(Array(viewStore.addresses), id: \.self) { row in
								HStack {
									TokenThumbnail(.xrd)
										.padding(.trailing, .medium3)

									VStack(alignment: .leading, spacing: .zero) {
										Text("XRD")
											.textStyle(.body1HighImportance)
											.foregroundColor(.app.gray1)
										AddressView(
											row.ledgerIdentifiable,
											isTappable: false
										)
										.foregroundColor(.app.gray2)
									}
									Spacer()
									AssetIcon(.asset(AssetResource.trash))
										.onTapGesture {
											viewStore.send(.view(.assetRemove(row)))
										}
								}
								.frame(minHeight: .largeButtonHeight)
							}
						}
						.scrollContentBackground(.hidden)
						.listStyle(.grouped)
					}
					Spacer()
				}
				.padding(.top, .medium1)
				.background(.app.gray5)
				.destination(store: store)
				.navigationTitle("Allow/Deny Specific Assets")
				.defaultNavBarConfig()
				.footer {
					Button("Add Asset", action: {
						viewStore.send(.view(.addAssetTapped))
					}).buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}

private extension View {
	@MainActor
	func destination(store: StoreOf<ResourcesList>) -> some View {
		let destinationStore = store.scope(state: \.$destinations, action: { .child(.destinations($0)) })
		return addAsset(with: destinationStore)
			.confirmDeletionAlert(with: destinationStore)
	}

	@MainActor
	func addAsset(with destinationStore: PresentationStoreOf<ResourcesList.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /ResourcesList.Destinations.State.addAsset,
			action: ResourcesList.Destinations.Action.addAsset,
			content: { AddAsset.View(store: $0) }
		)
	}

	@MainActor
	func confirmDeletionAlert(with destinationStore: PresentationStoreOf<ResourcesList.Destinations>) -> some View {
		alert(
			store: destinationStore,
			state: /ResourcesList.Destinations.State.confirmAssetDeletion,
			action: ResourcesList.Destinations.Action.confirmAssetDeletion
		)
	}
}
