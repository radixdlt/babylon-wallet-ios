import ComposableArchitecture
import SwiftUI
extension ResourcesList.State {
	// Need to disable, since broken in swiftformat 0.52.7
	// swiftformat:disable redundantClosure

	var viewState: ResourcesList.ViewState {
		.init(
			resources: .init(uncheckedUniqueElements: resourcesForDisplay),
			info: {
				switch mode {
				case .allowDenyAssets(.allow) where resourcesForDisplay.isEmpty:
					L10n.AccountSettings.SpecificAssetsDeposits.emptyAllowAll
				case .allowDenyAssets(.allow):
					L10n.AccountSettings.SpecificAssetsDeposits.allowInfo
				case .allowDenyAssets(.deny) where resourcesForDisplay.isEmpty:
					L10n.AccountSettings.SpecificAssetsDeposits.emptyDenyAll
				case .allowDenyAssets(.deny):
					L10n.AccountSettings.SpecificAssetsDeposits.denyInfo
				case .allowDepositors where resourcesForDisplay.isEmpty:
					L10n.AccountSettings.SpecificAssetsDeposits.allowDepositorsNoResources
				case .allowDepositors:
					L10n.AccountSettings.SpecificAssetsDeposits.allowDepositors
				}
			}(),
			mode: mode
		)
	}
	// swiftformat:enable redundantClosure
}

extension ResourcesList {
	public struct ViewState: Equatable {
		let resources: IdentifiedArrayOf<ResourceViewState>
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
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium1) {
					headerView(viewStore)
					if !viewStore.resources.isEmpty {
						listView(viewStore)
					}
					Spacer(minLength: 0)
				}
				.onFirstTask { @MainActor in
					await viewStore.send(.task).finish()
				}
				.padding(.top, .medium1)
				.background(.app.gray5)
				.destinations(with: store)
				.navigationTitle(viewStore.mode.navigationTitle)
				.defaultNavBarConfig()
				.footer {
					Button(viewStore.mode.addButtonTitle) {
						viewStore.send(.addAssetTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}

extension ResourcesList.View {
	@ViewBuilder
	func headerView(_ viewStore: ViewStoreOf<ResourcesList>) -> some SwiftUI.View {
		Group {
			if case let .allowDenyAssets(exceptionRule) = viewStore.mode {
				Picker(
					L10n.AccountSettings.SpecificAssetsDeposits.resourceListPicker,
					selection: viewStore.binding(
						get: { _ in exceptionRule },
						send: { .exceptionListChanged($0) }
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
	}

	@ViewBuilder
	func listView(_ viewStore: ViewStoreOf<ResourcesList>) -> some SwiftUI.View {
		List {
			ForEach(viewStore.resources) { row in
				resourceRowView(row, viewStore)
			}
		}
		.scrollContentBackground(.hidden)
		.listStyle(.grouped)
	}

	@ViewBuilder
	func resourceRowView(_ viewState: ResourceViewState, _ viewStore: ViewStoreOf<ResourcesList>) -> some SwiftUI.View {
		HStack {
			if case .globalNonFungibleResourceManager = viewState.address.resourceAddress.decodedKind {
				NFTThumbnail(viewState.iconURL)
			} else {
				TokenThumbnail(.known(viewState.iconURL))
			}

			VStack(alignment: .leading, spacing: .zero) {
				Text(viewState.name ?? "")
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.gray1)
				AddressView(
					viewState.address.ledgerIdentifiable,
					isTappable: false
				)
				.foregroundColor(.app.gray2)
			}
			.padding(.leading, .medium3)

			Spacer(minLength: 0)

			AssetIcon(.asset(AssetResource.trash))
				.onTapGesture {
					viewStore.send(.assetRemove(viewState.address))
				}
		}
		.frame(minHeight: .largeButtonHeight)
	}
}

private extension StoreOf<ResourcesList> {
	var destination: PresentationStoreOf<ResourcesList.Destination> {
		scope(state: \.$destination) { .destination($0) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ResourcesList>) -> some View {
		let destinationStore = store.destination
		return addAsset(with: destinationStore)
			.confirmDeletionAlert(with: destinationStore)
	}

	private func addAsset(with destinationStore: PresentationStoreOf<ResourcesList.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /ResourcesList.Destination.State.addAsset,
			action: ResourcesList.Destination.Action.addAsset,
			content: { AddAsset.View(store: $0) }
		)
	}

	private func confirmDeletionAlert(with destinationStore: PresentationStoreOf<ResourcesList.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /ResourcesList.Destination.State.confirmAssetDeletion,
			action: ResourcesList.Destination.Action.confirmAssetDeletion
		)
	}
}

extension ThirdPartyDeposits.DepositAddressExceptionRule {
	var text: String {
		switch self {
		case .allow:
			L10n.AccountSettings.SpecificAssetsDeposits.allow
		case .deny:
			L10n.AccountSettings.SpecificAssetsDeposits.deny
		}
	}
}

extension ResourcesListMode {
	var addButtonTitle: String {
		switch self {
		case .allowDenyAssets:
			L10n.AccountSettings.SpecificAssetsDeposits.addAnAssetButton
		case .allowDepositors:
			L10n.AccountSettings.ThirdPartyDeposits.allowSpecificDepositorsButton
		}
	}

	var navigationTitle: String {
		switch self {
		case .allowDenyAssets:
			L10n.AccountSettings.specificAssetsDeposits
		case .allowDepositors:
			L10n.AccountSettings.ThirdPartyDeposits.allowSpecificDepositors
		}
	}
}

extension ResourceViewState.Address {
	var ledgerIdentifiable: LedgerIdentifiable {
		switch self {
		case let .assetException(exception):
			.address(.resource(exception.address))

		case let .allowedDepositor(.resourceAddress(resourceAddress)):
			.address(.resource(resourceAddress))

		case let .allowedDepositor(.nonFungibleGlobalID(nonFungibleGlobalID)):
			.address(.nonFungibleGlobalID(nonFungibleGlobalID))
		}
	}
}
