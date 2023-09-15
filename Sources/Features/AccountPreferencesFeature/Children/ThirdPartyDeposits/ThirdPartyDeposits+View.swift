import FeaturePrelude

extension ManageThirdPartyDeposits.State {
	var viewState: ManageThirdPartyDeposits.ViewState {
		.init(sections: [
			.init(
				id: .depositRules,
				title: L10n.AccountSettings.ThirdPartyDeposits.text,
				rows: [
					.acceptAllMode(),
					.acceptKnownMode(),
					.denyAllMode(),
				],
				mode: .selection(.depositRule(depositRule))
			),
			.init(
				id: .allowDenyAssets,
				title: "",
				rows: [.allowDenyAssets()]
			),
			.init(id: .allowDepositors, title: nil, rows: [.allowDepositors()]),
		],
		updateButtonControlState: account.onLedgerSettings.thirdPartyDeposits == thirdPartyDeposits ? .disabled : .enabled)
	}
}

extension ManageThirdPartyDeposits {
	public struct ViewState: Equatable {
		let sections: [PreferenceSection<ManageThirdPartyDeposits.Section, ManageThirdPartyDeposits.Section.Row>.ViewState]
		let updateButtonControlState: ControlState
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<ManageThirdPartyDeposits>

		init(store: StoreOf<ManageThirdPartyDeposits>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				PreferencesList(
					viewState: .init(sections: viewStore.sections),
					onRowSelected: { _, row in viewStore.send(.rowTapped(row)) }
				)
				.background(.app.gray5)
				.navigationTitle(L10n.AccountSettings.thirdPartyDeposits)
				.defaultNavBarConfig()
				.destination(store: store)
				.footer {
					Button(L10n.AccountSettings.SpecificAssetsDeposits.update) {
						viewStore.send(.updateTapped)
					}
					.buttonStyle(.primaryRectangular)
					.controlState(viewStore.updateButtonControlState)
				}
			}
		}
	}
}

// MARK: - ManageThirdPartyDeposits.Section
extension ManageThirdPartyDeposits {
	public enum Section: Hashable, Sendable {
		case depositRules
		case allowDenyAssets
		case allowDepositors

		public enum Row: Hashable, Sendable {
			case depositRule(ThirdPartyDeposits.DepositRule)
			case allowDenyAssets(AllowDenyAssetsRow)
			case allowDepositors(AllowDepositorsRow)
		}

		public enum AllowDenyAssetsRow: Hashable, Sendable {
			case allowDenyAssets
		}

		public enum AllowDepositorsRow: Hashable, Sendable {
			case allowDepositors
		}
	}
}

extension PreferenceSection.Row where SectionId == ManageThirdPartyDeposits.Section, RowId == ManageThirdPartyDeposits.Section.Row {
	static func acceptAllMode() -> Self {
		.init(
			id: .depositRule(.acceptAll),
			title: L10n.AccountSettings.ThirdPartyDeposits.acceptAll,
			subtitle: L10n.AccountSettings.ThirdPartyDeposits.acceptAllSubtitle,
			icon: .asset(AssetResource.iconAcceptAirdrop)
		)
	}

	static func acceptKnownMode() -> Self {
		.init(
			id: .depositRule(.acceptKnown),
			title: L10n.AccountSettings.ThirdPartyDeposits.onlyKnown,
			subtitle: L10n.AccountSettings.ThirdPartyDeposits.onlyKnownSubtitle,
			icon: .asset(AssetResource.iconAcceptKnownAirdrop)
		)
	}

	static func denyAllMode() -> Self {
		.init(
			id: .depositRule(.denyAll),
			title: L10n.AccountSettings.ThirdPartyDeposits.denyAll,
			subtitle: L10n.AccountSettings.ThirdPartyDeposits.denyAllSubtitle,
			hint: L10n.AccountSettings.ThirdPartyDeposits.denyAllWarning,
			icon: .asset(AssetResource.iconDeclineAirdrop)
		)
	}

	static func allowDenyAssets() -> Self {
		.init(
			id: .allowDenyAssets(.allowDenyAssets),
			title: L10n.AccountSettings.specificAssetsDeposits,
			subtitle: L10n.AccountSettings.ThirdPartyDeposits.allowDenySpecificSubtitle
		)
	}

	static func allowDepositors() -> Self {
		.init(
			id: .allowDepositors(.allowDepositors),
			title: L10n.AccountSettings.ThirdPartyDeposits.allowSpecificDepositors,
			subtitle: L10n.AccountSettings.ThirdPartyDeposits.allowSpecificDepositorsSubtitle
		)
	}
}

extension View {
	@MainActor
	func destination(store: StoreOf<ManageThirdPartyDeposits>) -> some View {
		let destinationStore = store.scope(state: \.$destinations, action: { .child(.destinations($0)) })
		return allowDenyAssets(with: destinationStore)
			.allowDepositors(with: destinationStore)
	}

	@MainActor
	func allowDenyAssets(with destinationStore: PresentationStoreOf<ManageThirdPartyDeposits.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /ManageThirdPartyDeposits.Destinations.State.allowDenyAssets,
			action: ManageThirdPartyDeposits.Destinations.Action.allowDenyAssets,
			destination: { ResourcesList.View(store: $0) }
		)
	}

	@MainActor
	func allowDepositors(with destinationStore: PresentationStoreOf<ManageThirdPartyDeposits.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /ManageThirdPartyDeposits.Destinations.State.allowDepositors,
			action: ManageThirdPartyDeposits.Destinations.Action.allowDepositors,
			destination: { ResourcesList.View(store: $0) }
		)
	}
}
