import FeaturePrelude

extension AccountPreferences.State {
	var viewState: AccountPreferences.ViewState {
		.init(sections: [
			.init(
				id: .personalize,
				title: "Personalize this account", // FIXME: strings
				rows: [.accountLabel(account)]
			),
			.init(
				id: .ledgerBehaviour,
				title: "Set how you want this account to work", // FIXME: strings
				rows: [.thirdPartyDeposits()]
			),
			.init(
				id: .development,
				title: "Set development preferences", // FIXME: strings
				rows: [.devAccountPreferneces()]
			),
		])
	}
}

// MARK: - AccountPreferences.View
extension AccountPreferences {
	public struct ViewState: Equatable {
		var sections: [PreferenceSection<AccountPreferences.Section, AccountPreferences.Section.SectionRow>.ViewState]
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AccountPreferences>

		public init(store: StoreOf<AccountPreferences>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				PreferencesList(
					viewState: .init(sections: viewStore.sections),
					onRowSelected: { _, rowId in viewStore.send(.rowTapped(rowId)) }
				)
				.task {
					viewStore.send(.task)
				}
				.destination(store: store)
				.background(.app.gray5)
				.navigationTitle(L10n.AccountSettings.title)
				#if os(iOS)
					.navigationBarTitleColor(.app.gray1)
					.navigationBarTitleDisplayMode(.inline)
					.navigationBarInlineTitleFont(.app.secondaryHeader)
					.toolbarBackground(.app.background, for: .navigationBar)
					.toolbarBackground(.visible, for: .navigationBar)
				#endif // os(iOS)
			}
		}
	}
}

extension View {
	@MainActor
	func destination(store: StoreOf<AccountPreferences>) -> some View {
		let destinationStore = store.scope(state: \.$destinations, action: { .child(.destinations($0)) })
		return updateAccountLabel(with: destinationStore)
			.thirdPartyDeposits(with: destinationStore)
			.devAccountPreferences(with: destinationStore)
	}

	@MainActor
	func updateAccountLabel(with destinationStore: PresentationStoreOf<AccountPreferences.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountPreferences.Destinations.State.updateAccountLabel,
			action: AccountPreferences.Destinations.Action.updateAccountLabel,
			destination: { UpdateAccountLabel.View(store: $0) }
		)
	}

	@MainActor
	func thirdPartyDeposits(with destinationStore: PresentationStoreOf<AccountPreferences.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountPreferences.Destinations.State.thirdPartyDeposits,
			action: AccountPreferences.Destinations.Action.thirdPartyDeposits,
			destination: { ManageThirdPartyDeposits.View(store: $0) }
		)
	}

	@MainActor
	func devAccountPreferences(with destinationStore: PresentationStoreOf<AccountPreferences.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountPreferences.Destinations.State.devPreferences,
			action: AccountPreferences.Destinations.Action.devPreferences,
			destination: { DevAccountPreferences.View(store: $0) }
		)
	}
}

// MARK: - AccountPreferences.Section
extension AccountPreferences {
	public enum Section: Hashable, Sendable {
		case personalize
		case ledgerBehaviour
		case development

		public enum SectionRow: Hashable, Sendable {
			case personalize(PersonalizeRow)
			case onLedger(OnLedgerBehaviourRow)
			case dev(DevelopmentRow)
		}

		public enum PersonalizeRow: Hashable, Sendable {
			case accountLabel
			case accountColor
			case tags
		}

		public enum OnLedgerBehaviourRow: Hashable, Sendable {
			case accountSecurity
			case thirdPartyDeposits
		}

		public enum DevelopmentRow: Hashable, Sendable {
			case devPreferences
		}
	}
}

extension PreferenceSection.Row where RowId == AccountPreferences.Section.SectionRow {
	static func accountLabel(_ account: Profile.Network.Account) -> Self {
		.init(
			id: .personalize(.accountLabel),
			title: "Account Label", // FIXME: strings
			subtitle: account.displayName.rawValue,
			icon: .asset(AssetResource.create)
		)
	}

	static func devAccountPreferneces() -> Self {
		.init(
			id: .dev(.devPreferences),
			title: "Dev Preferences", // FIXME: strings
			subtitle: nil,
			icon: .asset(AssetResource.appSettings)
		)
	}

	// TODO: Pass the deposit mode
	static func thirdPartyDeposits() -> Self {
		.init(
			id: .onLedger(.thirdPartyDeposits),
			title: "Third-Party Deposits", // FIXME: strings
			subtitle: "Accept all deposits", // FIXME: strings
			icon: .asset(AssetResource.iconAcceptAirdrop)
		)
	}
}
