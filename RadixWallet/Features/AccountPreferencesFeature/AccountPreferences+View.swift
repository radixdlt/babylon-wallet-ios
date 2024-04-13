import ComposableArchitecture
import SwiftUI

extension AccountPreferences.State {
	var viewState: AccountPreferences.ViewState {
		.init(
			account: account,
			sections: {
				var sections: [AccountPreferences.ViewState.Section] = [
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
				]

				#if DEBUG
				addDevAccountPreferencesSection(to: &sections)
				#endif

				return sections
			}(),
			faucetButtonState: faucetButtonState,
			isOnMainnet: isOnMainnet
		)
	}

	func addDevAccountPreferencesSection(
		to sections: inout [AccountPreferences.ViewState.Section]
	) {
		sections.append(.init(
			id: .development,
			title: L10n.AccountSettings.developmentHeading,
			rows: [.devAccountPreferences()]
		))
	}
}

// MARK: - AccountPreferences.View
extension AccountPreferences {
	public struct ViewState: Equatable {
		typealias Section = PreferenceSection<AccountPreferences.Section, AccountPreferences.Section.SectionRow>.ViewState
		let account: Sargon.Account
		var sections: [Section]
		var faucetButtonState: ControlState
		var isOnMainnet: Bool
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

				Button(L10n.AddressAction.showAccountQR) {
					viewStore.send(.qrCodeButtonTapped)
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true))
				.padding(.horizontal, .medium3)
				.padding(.bottom, .medium3)

				PreferencesList(
					viewState: .init(sections: viewStore.sections),
					onRowSelected: { _, rowId in viewStore.send(.rowTapped(rowId)) },
					footer: { footer(with: viewStore) }
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
	@ViewBuilder
	private func footer(with viewStore: ViewStoreOf<AccountPreferences>) -> some View {
		VStack {
			if !viewStore.isOnMainnet {
				faucetButton(with: viewStore)
			}

			hideAccountButton()
		}
	}

	@ViewBuilder
	private func faucetButton(with viewStore: ViewStoreOf<AccountPreferences>) -> some View {
		Button(L10n.AccountSettings.getXrdTestTokens) {
			viewStore.send(.faucetButtonTapped)
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
		.controlState(viewStore.faucetButtonState)

		if viewStore.faucetButtonState.isLoading {
			Text(L10n.AccountSettings.loadingPrompt)
				.font(.app.body2Regular)
				.foregroundColor(.app.gray1)
		}
	}

	@MainActor
	private func hideAccountButton() -> some View {
		Button(L10n.AccountSettings.HideAccount.button) {
			store.send(.view(.hideAccountTapped))
		}
		.buttonStyle(.primaryRectangular(isDestructive: true))
	}
}

private extension StoreOf<AccountPreferences> {
	var destination: PresentationStoreOf<AccountPreferences.Destination> {
		func scopeState(state: State) -> PresentationState<AccountPreferences.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destination(store: StoreOf<AccountPreferences>) -> some View {
		let destinationStore = store.destination
		return showQRCode(with: destinationStore)
			.updateAccountLabel(with: destinationStore)
			.thirdPartyDeposits(with: destinationStore)
			.devAccountPreferences(with: destinationStore)
			.confirmHideAccountAlert(with: destinationStore)
	}

	private func showQRCode(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.showQR, action: \.showQR)) {
			ShowQR.View(store: $0)
		}
	}

	private func updateAccountLabel(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.updateAccountLabel, action: \.updateAccountLabel)) {
			UpdateAccountLabel.View(store: $0)
		}
	}

	private func thirdPartyDeposits(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.thirdPartyDeposits, action: \.thirdPartyDeposits)) {
			ManageThirdPartyDeposits.View(store: $0)
		}
	}

	private func devAccountPreferences(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.devPreferences, action: \.devPreferences)) {
			DevAccountPreferences.View(store: $0)
		}
	}

	private func confirmHideAccountAlert(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.confirmHideAccount, action: \.confirmHideAccount))
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
	static func accountLabel(_ account: Sargon.Account) -> Self {
		.init(
			id: .personalize(.accountLabel),
			title: L10n.AccountSettings.accountLabel,
			subtitle: account.displayName.rawValue,
			icon: .asset(AssetResource.create)
		)
	}

	static func thirdPartyDeposits(_ rule: DepositRule) -> Self {
		.init(
			id: .onLedger(.thirdPartyDeposits),
			title: L10n.AccountSettings.thirdPartyDeposits,
			subtitle: rule.text,
			icon: .asset(AssetResource.iconAcceptAirdrop)
		)
	}

	static func devAccountPreferences() -> Self {
		.init(
			id: .dev(.devPreferences),
			title: L10n.AccountSettings.devPreferences,
			subtitle: nil,
			icon: .asset(AssetResource.appSettings)
		)
	}
}

extension DepositRule {
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
