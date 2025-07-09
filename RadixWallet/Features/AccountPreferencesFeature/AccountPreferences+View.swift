import ComposableArchitecture
import SwiftUI

extension AccountPreferences.State {
	var viewState: AccountPreferences.ViewState {
		.init(
			account: account,
			factorSource: factorSource,
			sections: {
				var sections: [AccountPreferences.ViewState.Section] = [
					.init(
						id: .personalize,
						title: L10n.AccountSettings.personalizeHeading,
						rows: [.accountLabel]
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
			rows: [.devAccountPreferences]
		))
	}
}

// MARK: - AccountPreferences.View
extension AccountPreferences {
	struct ViewState: Equatable {
		typealias Section = PreferenceSection<AccountPreferences.Section, AccountPreferences.Section.SectionRow>.ViewState
		let account: Account
		let factorSource: FactorSourceIntegrity?
		let sections: [Section]
		let faucetButtonState: ControlState
		let isOnMainnet: Bool
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AccountPreferences>

		init(store: StoreOf<AccountPreferences>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				PreferencesList(
					viewState: .init(sections: viewStore.sections),
					onRowSelected: { _, rowId in viewStore.send(.rowTapped(rowId)) },
					header: {
						VStack(alignment: .leading) {
							AccountCard(account: viewStore.account)
							if let factorSource = viewStore.factorSource {
								Text("Secured with")
									.textStyle(.body1HighImportance)
									.foregroundColor(.secondaryText)
									.padding(.top, .medium3)

								FactorSourceCard(kind: .instance(factorSource: factorSource.factorSource, kind: .short(showDetails: false)), mode: .display)
									.padding(.bottom, .medium3)
									.onTapGesture {
										viewStore.send(.factorSourceCardTapped)
										// Open factor source details?
									}
							}
						}
					},
					footer: { footer(with: viewStore) }
				)
				.task {
					viewStore.send(.task)
				}
				.destination(store: store)
				.background(.secondaryBackground)
				.radixToolbar(title: L10n.AccountSettings.title)
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
			deleteAccountButton()
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
				.foregroundColor(.primaryText)
		}
	}

	@MainActor
	private func hideAccountButton() -> some View {
		Button(L10n.AccountSettings.HideAccount.button) {
			store.send(.view(.hideAccountTapped))
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
	}

	@MainActor
	private func deleteAccountButton() -> some View {
		Button(L10n.AccountSettings.deleteAccount) {
			store.send(.view(.deleteAccountTapped))
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
		return updateAccountLabel(with: destinationStore)
			.thirdPartyDeposits(with: destinationStore)
			.devAccountPreferences(with: destinationStore)
			.hideAccount(with: destinationStore, store: store)
			.deleteAccount(with: destinationStore, store: store)
			.factorSourceDetails(with: destinationStore, store: store)
	}

	private func updateAccountLabel(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.updateAccountLabel, action: \.updateAccountLabel)) {
			RenameLabel.View(store: $0)
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

	private func hideAccount(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>, store: StoreOf<AccountPreferences>) -> some View {
		sheet(store: destinationStore.scope(state: \.hideAccount, action: \.hideAccount)) { _ in
			ConfirmationView(kind: .hideAccount) { action in
				store.send(.destination(.presented(.hideAccount(action))))
			}
		}
	}

	private func deleteAccount(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>, store: StoreOf<AccountPreferences>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.deleteAccount, action: \.deleteAccount)) {
			DeleteAccountCoordinator.View(store: $0)
		}
	}

	private func factorSourceDetails(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>, store: StoreOf<AccountPreferences>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.factorSourceDetail, action: \.factorSourceDetail)) {
			FactorSourceDetail.View(store: $0)
		}
	}
}

// MARK: - AccountPreferences.Section
extension AccountPreferences {
	enum Section: Hashable, Sendable {
		case personalize
		case onLedgerBehaviour
		case development

		enum SectionRow: Hashable, Sendable {
			case personalize(PersonalizeRow)
			case onLedger(OnLedgerBehaviourRow)
			case dev(DevelopmentRow)
		}

		enum PersonalizeRow: Hashable, Sendable {
			case accountLabel
			case accountColor
			case tags
		}

		enum OnLedgerBehaviourRow: Hashable, Sendable {
			case accountSecurity
			case thirdPartyDeposits
		}

		enum DevelopmentRow: Hashable, Sendable {
			case devPreferences
		}
	}
}

extension PreferenceSection.Row where RowId == AccountPreferences.Section.SectionRow {
	static var accountLabel: Self {
		.init(
			id: .personalize(.accountLabel),
			title: L10n.AccountSettings.accountLabel,
			subtitle: L10n.AccountSettings.accountLabelSubtitle,
			icon: .asset(.create)
		)
	}

	static func thirdPartyDeposits(_ rule: DepositRule) -> Self {
		.init(
			id: .onLedger(.thirdPartyDeposits),
			title: L10n.AccountSettings.thirdPartyDeposits,
			subtitle: L10n.AccountSettings.thirdPartyDepositsSubtitle,
			icon: .asset(rule.icon)
		)
	}

	static var devAccountPreferences: Self {
		.init(
			id: .dev(.devPreferences),
			title: L10n.AccountSettings.devPreferences,
			subtitle: nil,
			icon: .asset(.appSettings)
		)
	}
}

extension DepositRule {
	var icon: ImageResource {
		switch self {
		case .acceptAll:
			.iconAcceptAirdrop
		case .acceptKnown:
			.iconAcceptKnownAirdrop
		case .denyAll:
			.iconDeclineAirdrop
		}
	}
}
