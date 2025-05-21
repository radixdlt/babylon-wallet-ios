import ComposableArchitecture
import SwiftUI

extension ResourcesList.State {
	private var resourcesForDisplay: [ResourceViewState] {
		switch mode {
		case let .allowDenyAssets(exception):
			let addresses: [ResourceViewState.Address] = thirdPartyDeposits.assetsExceptionSet()
				.filter { $0.exceptionRule == exception }
				.map { .assetException($0) }

			return loadedResources.filter { addresses.contains($0.address) }
		case .allowDepositors:
			return loadedResources
		}
	}

	var resources: IdentifiedArrayOf<ResourceViewState> {
		.init(uncheckedUniqueElements: resourcesForDisplay)
	}

	var info: String {
		guard canModify else {
			return L10n.AccountSettings.SpecificAssetsDeposits.modificationDisabledForRecoveredAccount
		}

		switch mode {
		case .allowDenyAssets(.allow) where resourcesForDisplay.isEmpty:
			return L10n.AccountSettings.SpecificAssetsDeposits.emptyAllowAll
		case .allowDenyAssets(.allow):
			return L10n.AccountSettings.SpecificAssetsDeposits.allowInfo
		case .allowDenyAssets(.deny) where resourcesForDisplay.isEmpty:
			return L10n.AccountSettings.SpecificAssetsDeposits.emptyDenyAll
		case .allowDenyAssets(.deny):
			return L10n.AccountSettings.SpecificAssetsDeposits.denyInfo
		case .allowDepositors where resourcesForDisplay.isEmpty:
			return L10n.AccountSettings.SpecificAssetsDeposits.allowDepositorsNoResources
		case .allowDepositors:
			return L10n.AccountSettings.SpecificAssetsDeposits.allowDepositors
		}
	}
}

// MARK: - ResourcesList.View
extension ResourcesList {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<ResourcesList>
		init(store: StoreOf<ResourcesList>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack(spacing: .medium1) {
					headerView(viewStore)
					items(resources: viewStore.resources)
				}
				.onFirstTask { @MainActor in
					await viewStore.send(.view(.task)).finish()
				}
				.padding(.top, .medium1)
				.background(.secondaryBackground)
				.destinations(with: store)
				.radixToolbar(title: viewStore.mode.navigationTitle)
				.footer {
					Button(viewStore.mode.addButtonTitle) {
						viewStore.send(.view(.addAssetTapped))
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
		_ viewStore: ViewStore<ResourcesList.State, ResourcesList.Action>
	) -> some SwiftUI.View {
		Group {
			if case let .allowDenyAssets(exceptionRule) = viewStore.mode {
				Picker(
					L10n.AccountSettings.SpecificAssetsDeposits.resourceListPicker,
					selection: viewStore.binding(
						get: { _ in exceptionRule },
						send: { .view(.exceptionListChanged($0)) }
					)
				) {
					ForEach(DepositAddressExceptionRule.allCases, id: \.self) {
						Text($0.text)
					}
				}
				.tint(.primaryBackground)
				.pickerStyle(.segmented)
				.padding(.horizontal, .small3)
			}

			Text(viewStore.info)
				.textStyle(.body1HighImportance)
				.foregroundColor(.secondaryText)
				.multilineTextAlignment(.center)
		}
		.padding(.horizontal, .medium3)
	}

	private func items(resources: IdentifiedArrayOf<ResourceViewState>) -> some SwiftUI.View {
		ScrollView {
			VStack(spacing: .medium3) {
				ForEach(resources) { resource in
					Card {
						AssetRow(
							name: resource.name,
							address: resource.address.ledgerIdentifiable,
							type: resource.thumbnailType,
							url: resource.iconURL,
							accessory: { accesoryView(resource: resource) }
						)
					}
				}
			}
			.padding(.horizontal, .medium3)
		}
	}

	private func accesoryView(resource: ResourceViewState) -> some SwiftUI.View {
		Image(.trash)
			.onTapGesture {
				store.send(.view(.assetRemove(resource.address)))
			}
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
			title: name,
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

private extension ResourceViewState.Address {
	var ledgerIdentifiable: LedgerIdentifiable.Address {
		switch self {
		case let .assetException(exception):
			.resource(exception.address)

		case let .allowedDepositor(.resource(resourceAddress)):
			.resource(resourceAddress)

		case let .allowedDepositor(.nonFungible(nonFungibleGlobalID)):
			.nonFungibleGlobalID(nonFungibleGlobalID)
		}
	}
}
