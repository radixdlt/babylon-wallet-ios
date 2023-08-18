import FeaturePrelude

extension ThirdPartyDeposits.State {
	var viewState: ThirdPartyDeposits.ViewState {
		.init(sections: [
			.init(
				id: .depositsMode,
				title: "Choose if you want to allow third-parties to directly deposit assets into your account. Deposits that you approve yourself in your Radix Wallet are always accepted.",
				rows: [
					.acceptAllMode(),
					.acceptKnownMode(),
					.denyAllMode(),
				],
				mode: .selection(.depositsMode(depositMode))
			),
			.init(
				id: .allowDenyAssets,
				title: "",
				rows: [.allowDenyAssets()]
			),
		])
	}
}

extension ThirdPartyDeposits {
	public struct ViewState: Equatable {
		let sections: [PreferenceSection<ThirdPartyDeposits.Section, ThirdPartyDeposits.Section.Row>.ViewState]
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<ThirdPartyDeposits>

		init(store: StoreOf<ThirdPartyDeposits>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				PreferencesList(viewState: .init(sections: viewStore.sections), onRowSelected: { _, row in
					viewStore.send(.rowTapped(row))
				})
				.background(.app.gray4)
				.navigationTitle("Third-party Deposits") // FIXME: strings
				.defaultNavBarConfig()
				.destination(store: store)
				.footer {
					Button("Update", action: {}).buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}

// MARK: - ThirdPartyDeposits.Section
extension ThirdPartyDeposits {
	public enum Section: Hashable {
		case depositsMode
		case allowDenyAssets

		public enum Row: Hashable {
			case depositsMode(State.ThirdPartyDepositMode)
			case allowDenyAssets(AllowDenyAssetsRow)
		}

		public enum AllowDenyAssetsRow: Hashable {
			case allowDenyAssets
		}
	}
}

extension PreferenceSection.Row where SectionId == ThirdPartyDeposits.Section, RowId == ThirdPartyDeposits.Section.Row {
	static func acceptAllMode() -> Self {
		.init(
			id: .depositsMode(.acceptAll),
			title: "Accept All", // FIXME: strings
			subtitle: "Allow third parties to deposit any asset",
			icon: .asset(AssetResource.iconAcceptAirdrop)
		)
	}

	static func acceptKnownMode() -> Self {
		.init(
			id: .depositsMode(.acceptKnown),
			title: "Only accept known", // FIXME: strings
			subtitle: "Allow third parties to deposit only assets this account has held",
			icon: .asset(AssetResource.iconAcceptKnownAirdrop)
		)
	}

	static func denyAllMode() -> Self {
		.init(
			id: .depositsMode(.denyAll),
			title: "Deny all", // FIXME: strings
			subtitle: "Deny all third parties deposits", // FIXME: strings
			icon: .asset(AssetResource.iconDeclineAirdrop)
		)
	}

	static func allowDenyAssets() -> Self {
		.init(
			id: .allowDenyAssets(.allowDenyAssets),
			title: "Allow/Deny specific assets", // FIXME: strings
			subtitle: "Deny or allow third-party deposits of specific assets, ignoring the setting above", // FIXME: strings
			icon: nil
		)
	}
}

extension View {
	@MainActor
	func destination(store: StoreOf<ThirdPartyDeposits>) -> some View {
		let destinationStore = store.scope(state: \.$destinations, action: { .child(.destinations($0)) })
		return allowDenyAssets(with: destinationStore)
	}

	@MainActor
	func allowDenyAssets(with destinationStore: PresentationStoreOf<ThirdPartyDeposits.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /ThirdPartyDeposits.Destinations.State.allowDenyAssets,
			action: ThirdPartyDeposits.Destinations.Action.allowDenyAssets,
			destination: { AllowDenyAssets.View(store: $0) }
		)
	}
}
