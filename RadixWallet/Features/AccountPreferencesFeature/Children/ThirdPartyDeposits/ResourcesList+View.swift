import ComposableArchitecture
import SwiftUI

extension ResourcesList.State {
	// Need to disable, since broken in swiftformat 0.52.7
	// swiftformat:disable redundantClosure

	var viewState: ResourcesList.ViewState {
		.init(
			canModify: canModify,
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
		let canModify: Bool
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
					items(resources: viewStore.resources)
				}
				.onFirstTask { @MainActor in
					await viewStore.send(.task).finish()
				}
				.padding(.top, .medium1)
				.background(.app.gray5)
				.destinations(with: store)
				.radixToolbar(title: viewStore.mode.navigationTitle)
				.footer {
					Button(viewStore.mode.addButtonTitle) {
						viewStore.send(.addAssetTapped)
					}
					.buttonStyle(.primaryRectangular)
					.controlState(viewStore.canModify ? .enabled : .disabled)
				}
			}
		}
	}
}

extension ResourcesList.View {
	@ViewBuilder
	func headerView(
		_ viewStore: ViewStoreOf<ResourcesList>
	) -> some SwiftUI.View {
		Group {
			if case let .allowDenyAssets(exceptionRule) = viewStore.mode {
				Picker(
					L10n.AccountSettings.SpecificAssetsDeposits.resourceListPicker,
					selection: viewStore.binding(
						get: { _ in exceptionRule },
						send: { .exceptionListChanged($0) }
					)
				) {
					ForEach(DepositAddressExceptionRule.allCases, id: \.self) {
						Text($0.text)
					}
				}
				.pickerStyle(.segmented)
				.padding(.horizontal, .small3)
			}

			Text(viewStore.info)
				.textStyle(.body1HighImportance)
				.foregroundColor(.app.gray2)
				.multilineTextAlignment(.center)

			if !viewStore.canModify {
				Text(L10n.AccountSettings.SpecificAssetsDeposits.modificationDisabledForRecoveredAccount)
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.gray2)
					.multilineTextAlignment(.center)
			}
		}
		.padding(.horizontal, .medium3)
	}

	private func items(resources: IdentifiedArrayOf<ResourceViewState>) -> some SwiftUI.View {
		ScrollView {
			VStack(spacing: .zero) {
				ForEach(resources) { resource in
					PlainListRow(viewState: .init(
						rowCoreViewState: resource.rowCoreViewState,
						accessory: accesoryView(resource: resource),
						icon: { iconView(resource: resource) }
					))
					.background(Color.app.white)
					.withSeparator
				}
			}
		}
	}

	private func accesoryView(resource: ResourceViewState) -> AnyView {
		Image(.trash)
			.onTapGesture {
				store.send(.view(.assetRemove(resource.address)))
			}
			.eraseToAnyView()
	}

	private func iconView(resource: ResourceViewState) -> some SwiftUI.View {
		Thumbnail(resource.thumbnailType, url: resource.iconURL).eraseToAnyView()
	}
}

private extension ResourceViewState {
	var thumbnailType: Thumbnail.ContentType {
		if address.resourceAddress.isNonFungible {
			.nft
		} else if address.resourceAddress.isXRD {
			.token(.xrd)
		} else {
			.token(.other)
		}
	}

	var rowCoreViewState: PlainListRowCore.ViewState {
		.init(
			title: name ?? "-",
			subtitle: address.resourceAddress.formatted()
		)
	}
}

private extension StoreOf<ResourcesList> {
	var destination: PresentationStoreOf<ResourcesList.Destination> {
		func scopeState(state: State) -> PresentationState<ResourcesList.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(
		with store: StoreOf<ResourcesList>
	) -> some View {
		let destinationStore = store.destination
		return addAsset(with: destinationStore)
			.confirmDeletionAlert(with: destinationStore)
	}

	private func addAsset(
		with destinationStore: PresentationStoreOf<ResourcesList.Destination>
	) -> some View {
		sheet(store: destinationStore.scope(state: \.addAsset, action: \.addAsset)) {
			AddAsset.View(store: $0)
		}
	}

	private func confirmDeletionAlert(
		with destinationStore: PresentationStoreOf<ResourcesList.Destination>
	) -> some View {
		alert(store: destinationStore.scope(state: \.confirmAssetDeletion, action: \.confirmAssetDeletion))
	}
}

extension DepositAddressExceptionRule {
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

		case let .allowedDepositor(.resource(resourceAddress)):
			.address(.resource(resourceAddress))

		case let .allowedDepositor(.nonFungible(nonFungibleGlobalID)):
			.address(.nonFungibleGlobalID(nonFungibleGlobalID))
		}
	}
}
