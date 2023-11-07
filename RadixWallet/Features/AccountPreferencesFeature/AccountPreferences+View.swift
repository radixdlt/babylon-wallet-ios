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
					title: L10n.AccountSettings.developmentHeading,
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

				Button("Show Address QR Code") { // FIXME: Strings - L10n.AccountSettings.showQR
					viewStore.send(.qrCodeButtonTapped)
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true))
				.padding(.horizontal, .medium3)
				.padding(.bottom, .medium3)

				PreferencesList(
					viewState: .init(sections: viewStore.sections),
					onRowSelected: { _, rowId in viewStore.send(.rowTapped(rowId)) },
					footer: { hideAccountButton() }
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

extension AccountPreferences.View {
	@MainActor
	func hideAccountButton() -> some View {
		Button(L10n.AccountSettings.HideAccount.button) {
			store.send(.view(.hideAccountTapped))
		}
		.buttonStyle(.primaryRectangular(isDestructive: true))
	}
}

extension View {
	@MainActor
	func destination(store: StoreOf<AccountPreferences>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
		return showQRCode(with: destinationStore)
			.updateAccountLabel(with: destinationStore)
			.thirdPartyDeposits(with: destinationStore)
			.devAccountPreferences(with: destinationStore)
			.confirmHideAccountAlert(with: destinationStore)
	}

	@MainActor
	func showQRCode(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /AccountPreferences.Destination.State.showQR,
			action: AccountPreferences.Destination.Action.showQR
		) {
			ShowQR.View(store: $0)
		}
	}

	@MainActor
	func updateAccountLabel(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountPreferences.Destination.State.updateAccountLabel,
			action: AccountPreferences.Destination.Action.updateAccountLabel,
			destination: { UpdateAccountLabel.View(store: $0) }
		)
	}

	@MainActor
	func thirdPartyDeposits(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountPreferences.Destination.State.thirdPartyDeposits,
			action: AccountPreferences.Destination.Action.thirdPartyDeposits,
			destination: { ManageThirdPartyDeposits.View(store: $0) }
		)
	}

	@MainActor
	func devAccountPreferences(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AccountPreferences.Destination.State.devPreferences,
			action: AccountPreferences.Destination.Action.devPreferences,
			destination: { DevAccountPreferences.View(store: $0) }
		)
	}

	@MainActor
	func confirmHideAccountAlert(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /AccountPreferences.Destination.State.confirmHideAccount,
			action: AccountPreferences.Destination.Action.confirmHideAccount
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
			title: L10n.AccountSettings.devPreferences,
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
