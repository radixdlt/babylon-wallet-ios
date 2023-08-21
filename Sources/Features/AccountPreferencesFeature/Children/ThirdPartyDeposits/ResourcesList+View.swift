import EngineKit
import FeaturePrelude

extension ResourcesList.State {
	var viewState: ResourcesList.ViewState {
		.init(
			addresses: resourceAddresses,
			info: {
				switch mode {
				case .allowDenyAssets(.allow) where resourceAddresses.isEmpty:
					return "Add a specific asset by its resource address to allow all third-party deposits"
				case .allowDenyAssets(.allow):
					return "The following resource addresses may always be deposited to this account by third parties."
				case .allowDenyAssets(.deny) where resourceAddresses.isEmpty:
					return "Add a specific asset by its resource address to deny all third-party deposits"
				case .allowDenyAssets(.deny):
					return "The following resource addresses may never be deposited to this account by third parties."
				case .allowDepositors where resourceAddresses.isEmpty:
					return "Add a specific badge by its resource address to allow all deposits from its holder"
				case .allowDepositors:
					return "The holder of the following badges may always deposit accounts to this account."
				}
			}(),
			mode: mode
		)
	}
}

extension ResourcesList {
	public struct ViewState: Equatable {
		let addresses: OrderedSet<ThirdPartyDeposits.DepositAddress>
		let info: String
		let mode: ResourcesListMode
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
					Group {
						if case let .allowDenyAssets(exceptionRule) = viewStore.mode {
							Picker(
								"",
								selection: viewStore.binding(
									get: { _ in exceptionRule },
									send: { .view(.exceptionListChanged($0)) }
								)
							) {
								ForEach(ThirdPartyDeposits.DepositAddressExceptionRule.allCases, id: \.self) {
									Text($0.text)
								}
							}
							.pickerStyle(.segmented)
						}

						Text(viewStore.info)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)
							.multilineTextAlignment(.center)
					}
					.padding(.horizontal, .medium1)

					if !viewStore.addresses.isEmpty {
						List {
							ForEach(viewStore.addresses, id: \.self) { row in
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
				.task {
					viewStore.send(.view(.onAppeared))
				}
				.padding(.top, .medium1)
				.background(.app.gray5)
				.destination(store: store)
				.navigationTitle(viewStore.mode.navigationTitle)
				.defaultNavBarConfig()
				.footer {
					Button(viewStore.mode.addButtonTitle, action: {
						viewStore.send(.view(.addAssetTapped))
					}).buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}

// extension ResourcesList.View {
//    func resourceRow() -> some SwiftUI.View {
//
//    }
// }

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

extension ThirdPartyDeposits.DepositAddressExceptionRule {
	var text: String {
		switch self {
		case .allow:
			return "Allow"
		case .deny:
			return "Deny"
		}
	}
}

extension ResourcesListMode {
	var addButtonTitle: String {
		switch self {
		case .allowDenyAssets:
			return "Add Asset"
		case .allowDepositors:
			return "Add Depositor Badge"
		}
	}

	var navigationTitle: String {
		switch self {
		case .allowDenyAssets:
			return "Allow/Deny Specific Assets"
		case .allowDepositors:
			return "Allow Specific Depositors"
		}
	}
}

extension ThirdPartyDeposits.DepositAddress {
	var ledgerIdentifiable: LedgerIdentifiable {
		switch self {
		case let .resourceAddress(address):
			return .address(.resource(address))
		case let .nonFungibleGlobalID(id):
			return .address(.nonFungibleGlobalID(id))
		}
	}
}
