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
	public struct ViewState: Equatable {
		typealias Section = PreferenceSection<AccountPreferences.Section, AccountPreferences.Section.SectionRow>.ViewState
		let account: Account
		let sections: [Section]
		let faucetButtonState: ControlState
		let isOnMainnet: Bool
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
					onRowSelected: { _, rowId in viewStore.send(.rowTapped(rowId)) },
					header: { header(for: viewStore.account) },
					footer: { footer(with: viewStore) }
				)
				.task {
					viewStore.send(.task)
				}
				.destination(store: store)
				.background(.app.gray5)
				.radixToolbar(title: L10n.AccountSettings.title)
			}
		}
	}
}

extension AccountPreferences.View {
	private func header(for account: Account) -> some View {
		HStack(spacing: .small3) {
			Text(account.displayName.rawValue)
				.lineLimit(1)
				.textStyle(.body1Header)
				.foregroundColor(.app.white)
				.truncationMode(.tail)
				.layoutPriority(0)

			Spacer()

			AddressView(.address(of: account))
				.foregroundColor(.app.whiteTransparent)
				.textStyle(.body2HighImportance)
		}
		.padding(.horizontal, .medium1)
		.padding(.vertical, .medium2)
		.background(account.appearanceId.gradient)
		.cornerRadius(.small1)
	}

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
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
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
	}

	private func updateAccountLabel(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.updateAccountLabel, action: \.updateAccountLabel)) {
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

	private func hideAccount(with destinationStore: PresentationStoreOf<AccountPreferences.Destination>, store: StoreOf<AccountPreferences>) -> some View {
		sheet(store: destinationStore.scope(state: \.hideAccount, action: \.hideAccount)) { _ in
			HideAccountView { action in
				store.send(.destination(.presented(.hideAccount(action))))
			}
		}
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
	static var accountLabel: Self {
		.init(
			id: .personalize(.accountLabel),
			context: .settings,
			title: L10n.AccountSettings.accountLabel,
			subtitle: L10n.AccountSettings.accountLabelSubtitle,
			icon: .asset(AssetResource.create)
		)
	}

	static func thirdPartyDeposits(_ rule: DepositRule) -> Self {
		.init(
			id: .onLedger(.thirdPartyDeposits),
			context: .settings,
			title: L10n.AccountSettings.thirdPartyDeposits,
			subtitle: L10n.AccountSettings.thirdPartyDepositsSubtitle,
			icon: .asset(rule.icon)
		)
	}

	static var devAccountPreferences: Self {
		.init(
			id: .dev(.devPreferences),
			context: .settings,
			title: L10n.AccountSettings.devPreferences,
			subtitle: nil,
			icon: .asset(AssetResource.appSettings)
		)
	}
}

extension DepositRule {
	var icon: ImageAsset {
		switch self {
		case .acceptAll:
			AssetResource.iconAcceptAirdrop
		case .acceptKnown:
			AssetResource.iconAcceptKnownAirdrop
		case .denyAll:
			AssetResource.iconDeclineAirdrop
		}
	}
}
