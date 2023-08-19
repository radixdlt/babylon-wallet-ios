import EngineKit
import FeaturePrelude

extension AllowDenyAssets.State {
	var viewState: AllowDenyAssets.ViewState {
		.init(
			selectedList: list,
			info: {
				switch list {
				case .allow where allowList.isEmpty:
					return "Add a specific asset by its resource address to allow all third-party deposits"
				case .deny where denyList.isEmpty:
					return "Add a specific asset by its resource address to deny all third-party deposits"
				case .allow where !allowList.isEmpty:
					return "The following resource addresses may always be deposited to this account by third parties."
				case .deny where !denyList.isEmpty:
					return "The following resource addresses may never be deposited to this account by third parties."
				default:
					return ""
				}
			}(),
			resources: list == .allow ? allowList : denyList
		)
	}
}

extension AllowDenyAssets {
	public struct ViewState: Equatable {
		let selectedList: State.List
		let info: String
		let resources: Set<DepositAddress>
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<AllowDenyAssets>
		init(store: StoreOf<AllowDenyAssets>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				VStack(spacing: .medium1) {
					Group {
						Picker(
							"What is your favorite color?",
							selection: viewStore.binding(get: \.selectedList, send: { .view(.listChanged($0)) })
						) {
							ForEach(State.List.allCases, id: \.self) {
								Text($0.text)
							}
						}
						.pickerStyle(.segmented)

						Text(viewStore.info)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)
							.multilineTextAlignment(.center)
					}
					.padding(.horizontal, .medium1)

					if !viewStore.resources.isEmpty {
						List {
							ForEach(Array(viewStore.resources), id: \.self) { row in
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

extension AllowDenyAssets.State.List {
	var text: String {
		switch self {
		case .allow:
			return "Allow"
		case .deny:
			return "Deny"
		}
	}
}

extension View {
	@MainActor
	func destination(store: StoreOf<AllowDenyAssets>) -> some View {
		let destinationStore = store.scope(state: \.$destinations, action: { .child(.destinations($0)) })
		return addAsset(with: destinationStore)
			.confirmDeletionAlert(with: destinationStore)
	}

	@MainActor
	func addAsset(with destinationStore: PresentationStoreOf<AllowDenyAssets.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /AllowDenyAssets.Destinations.State.addAsset,
			action: AllowDenyAssets.Destinations.Action.addAsset,
			content: { AddAsset.View(store: $0) }
		)
	}

	@MainActor
	func confirmDeletionAlert(with destinationStore: PresentationStoreOf<AllowDenyAssets.Destinations>) -> some View {
		alert(
			store: destinationStore,
			state: /AllowDenyAssets.Destinations.State.confirmAssetDeletion,
			action: AllowDenyAssets.Destinations.Action.confirmAssetDeletion
		)
	}
}

extension DepositAddress {
	var ledgerIdentifiable: LedgerIdentifiable {
		switch self {
		case let .resource(address):
			return .address(.resource(address))
		case let .nftID(id):
			return .address(.nonFungibleGlobalID(id))
		}
	}
}
