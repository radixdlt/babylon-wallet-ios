import FeaturePrelude

extension ManageThirdPartyDeposits.State {
	var viewState: ManageThirdPartyDeposits.ViewState {
		.init(sections: [
			.init(
				id: .depositRules,
				title: "Choose if you want to allow third-parties to directly deposit assets into your account. Deposits that you approve yourself in your Radix Wallet are always accepted.",
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
				.navigationTitle("Third-party Deposits") // FIXME: strings
				.defaultNavBarConfig()
				.destination(store: store)
				.footer {
					Button("Update") { // FIXME: strings
						viewStore.send(.updateTapped)
					}
					.controlState(viewStore.updateButtonControlState)
					.buttonStyle(.primaryRectangular)
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
			title: "Accept All", // FIXME: strings
			subtitle: "Allow third parties to deposit any asset",
			icon: .asset(AssetResource.iconAcceptAirdrop)
		)
	}

	static func acceptKnownMode() -> Self {
		.init(
			id: .depositRule(.acceptKnown),
			title: "Only accept known", // FIXME: strings
			subtitle: "Allow third parties to deposit only assets this account has held",
			icon: .asset(AssetResource.iconAcceptKnownAirdrop)
		)
	}

	static func denyAllMode() -> Self {
		.init(
			id: .depositRule(.denyAll),
			title: "Deny all", // FIXME: strings
			subtitle: "Deny all third parties deposits", // FIXME: strings
			hint: "This account will not be able to receive “air drops” or be used by a trusted contact to assist with account recovery.", // FIXME: strings
			icon: .asset(AssetResource.iconDeclineAirdrop)
		)
	}

	static func allowDenyAssets() -> Self {
		.init(
			id: .allowDenyAssets(.allowDenyAssets),
			title: "Allow/Deny specific assets", // FIXME: strings
			subtitle: "Deny or allow third-party deposits of specific assets, ignoring the setting above"
		)
	}

	static func allowDepositors() -> Self {
		.init(
			id: .allowDepositors(.allowDepositors),
			title: "Allow specific depositors", // FIXME: strings
			subtitle: "Allow certain third party depositors to deposit assets freely"
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
