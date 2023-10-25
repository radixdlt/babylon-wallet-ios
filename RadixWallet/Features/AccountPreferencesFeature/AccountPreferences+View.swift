import ComposableArchitecture
import SwiftUI
extension AccountPreferences.State {
	var viewState: AccountPreferences.ViewState {
		.init(
			account: account,
			sections: [
				.init(
					id: .personalize,
					title: L10n.AccountSettings.personalizeHeading,
					rows: [.accountLabel(account)]
				),
				.init(
					id: .onLedgerBehaviour,
					title: L10n.AccountSettings.setBehaviorHeading,
					rows: [.thirdPartyDeposits(account.onLedgerSettings.thirdPartyDeposits.depositRule)]
				),
				.init(
					id: .development,
					title: "Set development preferences", // FIXME: strings
					rows: [.devAccountPreferneces()]
				),
			]
		)
	}
}

// MARK: - AccountPreferences.View
extension AccountPreferences {
	public struct ViewState: Equatable {
		let account: Profile.Network.Account
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
				AddressView(.address(of: viewStore.account), showFull: true)
					.textStyle(.body2Regular)
					.foregroundColor(.app.gray2)
					.padding(.top, .small1)
					.padding(.horizontal, .medium3)
					.padding(.bottom, .medium3)

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
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.inline)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
				.toolbarBackground(.app.background, for: .navigationBar)
				.toolbarBackground(.visible, for: .navigationBar)
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
		case onLedgerBehaviour
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
			title: L10n.AccountSettings.accountLabel,
			subtitle: account.displayName.rawValue,
			icon: .asset(AssetResource.create)
		)
	}

	static func thirdPartyDeposits(_ rule: ThirdPartyDeposits.DepositRule) -> Self {
		.init(
			id: .onLedger(.thirdPartyDeposits),
			title: L10n.AccountSettings.thirdPartyDeposits,
			subtitle: rule.text,
			icon: .asset(AssetResource.iconAcceptAirdrop)
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
}

extension ThirdPartyDeposits.DepositRule {
	var text: String {
		switch self {
		case .acceptAll:
			L10n.AccountSettings.ThirdPartyDeposits.acceptAll
		case .acceptKnown:
			L10n.AccountSettings.ThirdPartyDeposits.onlyKnown
		case .denyAll:
			L10n.AccountSettings.ThirdPartyDeposits.denyAll
		}
	}
}
