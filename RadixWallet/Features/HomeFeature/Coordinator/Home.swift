import ComposableArchitecture
import SwiftUI

// MARK: - Home
public struct Home: Sendable, FeatureReducer {
	public static let radixBannerURL = URL(string: "https://wallet.radixdlt.com/?wallet=downloaded")!

	public struct State: Sendable, Hashable {
		// MARK: - Components
		public var accountRows: IdentifiedArrayOf<Home.AccountRow.State> = []
		public var shouldWriteDownPersonasSeedPhrase: Bool = false

		public var showRadixBanner: Bool = false
		var showFiatWorth: Bool = true
		var accountPortfolios: Loadable<[OnLedgerEntity.Account]> = .idle

		// MARK: - Destination
		@PresentationState
		public var destination: Destination.State? = nil

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstAppear
		case task
		case pullToRefreshStarted
		case createAccountButtonTapped
		case settingsButtonTapped
		case radixBannerButtonTapped
		case radixBannerDismissButtonTapped
		case showFiatWorthToggled
	}

	public enum InternalAction: Sendable, Equatable {
		public typealias HasAccessToMnemonic = Bool
		case accountsLoadedResult(TaskResult<IdentifiedArrayOf<Profile.Network.Account>>)
		case exportMnemonic(account: Profile.Network.Account)
		case importMnemonic
		case loadedShouldWriteDownPersonasSeedPhrase(Bool)
		case loadIsCurrencyAmountVisible(Bool)
		case loadedPortfolios([OnLedgerEntity.Account])
	}

	public enum ChildAction: Sendable, Equatable {
		case account(id: Home.AccountRow.State.ID, action: Home.AccountRow.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case displaySettings
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case accountDetails(AccountDetails.State)
			case createAccount(CreateAccountCoordinator.State)
			case importMnemonics(ImportMnemonicsFlowCoordinator.State)
			case exportMnemonic(ExportMnemonic.State)
			case acknowledgeJailbreakAlert(AlertState<Action.AcknowledgeJailbreakAlert>)
		}

		public enum Action: Sendable, Equatable {
			case accountDetails(AccountDetails.Action)
			case createAccount(CreateAccountCoordinator.Action)
			case importMnemonics(ImportMnemonicsFlowCoordinator.Action)
			case exportMnemonic(ExportMnemonic.Action)
			case acknowledgeJailbreakAlert(AcknowledgeJailbreakAlert)

			public enum AcknowledgeJailbreakAlert: Sendable, Hashable {}
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.accountDetails, action: /Action.accountDetails) {
				AccountDetails()
			}
			Scope(state: /State.createAccount, action: /Action.createAccount) {
				CreateAccountCoordinator()
			}
			Scope(state: /State.importMnemonics, action: /Action.importMnemonics) {
				ImportMnemonicsFlowCoordinator()
			}
			Scope(state: /State.exportMnemonic, action: /Action.exportMnemonic) {
				ExportMnemonic()
			}
		}
	}

	@Dependency(\.openURL) var openURL
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.iOSSecurityClient) var iOSSecurityClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.accountRows, action: /Action.child .. ChildAction.account) {
				Home.AccountRow()
			}
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstAppear:
			if iOSSecurityClient.isJailbroken() {
				state.destination = .acknowledgeJailbreakAlert(.init(
					title: .init(L10n.Splash.RootDetection.titleIOS),
					message: .init(L10n.Splash.RootDetection.messageIOS),
					buttons: [
						.cancel(.init(L10n.Splash.RootDetection.acknowledgeButton)),
					]
				))
			}
			return loadAccountsPortfolios()

		case .task:
			state.showRadixBanner = userDefaults.showRadixBanner

			return .run { send in
				for try await accounts in await accountsClient.accountsOnCurrentNetwork() {
					guard !Task.isCancelled else { return }
					await send(.internal(.accountsLoadedResult(.success(accounts))))
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
			.merge(with: checkAccountsAccessToMnemonic(state: state))
			.merge(with: loadShouldWriteDownPersonasSeedPhrase())
			.merge(with: loadIsCurrencyAmountVisible())

		case .createAccountButtonTapped:
			state.destination = .createAccount(
				.init(config: .init(
					purpose: .newAccountFromHome
				))
			)
			return .none
		case .pullToRefreshStarted:
			let accountAddresses = state.accounts.map(\.address)
			return .run { _ in
				_ = try await accountPortfoliosClient.fetchAccountPortfolios(accountAddresses, true)
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		case .radixBannerButtonTapped:
			return .run { _ in
				await openURL(Home.radixBannerURL)
			}

		case .radixBannerDismissButtonTapped:
			userDefaults.setShowRadixBanner(false)
			state.showRadixBanner = false
			return .none

		case .settingsButtonTapped:
			return .send(.delegate(.displaySettings))

		case .showFiatWorthToggled:

			return .run { [isCurrencyAmountVisible = state.showFiatWorth] _ in
				try await appPreferencesClient.update(isCurrencyAmountVisible: !isCurrencyAmountVisible)
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountsLoadedResult(.success(accounts)):
			guard accounts.elements != state.accounts.elements else {
				return .none
			}

			state.accountRows = accounts.map { Home.AccountRow.State(account: $0) }.asIdentifiable()

			return .run { [addresses = state.accountAddresses] _ in
				_ = try await accountPortfoliosClient.fetchAccountPortfolios(addresses, false)
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
			.merge(with: checkAccountsAccessToMnemonic(state: state))

		case let .loadedPortfolios(portfolios):
			state.accountPortfolios = .success(portfolios)
			state.accountRows.mutateAll { rowState in
				if let portfolio = portfolios.first(where: { $0.address == rowState.id }) {
					rowState.portfolio = .success(portfolio)
				}
			}
			return .none

		case let .accountsLoadedResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .loadedShouldWriteDownPersonasSeedPhrase(shouldBackup):
			state.shouldWriteDownPersonasSeedPhrase = shouldBackup
			return .none

		case let .loadIsCurrencyAmountVisible(isVisible):
			state.showFiatWorth = isVisible
			return .none

		case let .exportMnemonic(account):
			return exportMnemonic(controlling: account, state: &state)

		case .importMnemonic:
			return importMnemonics(state: &state)
		}
	}

	private func checkAccountsAccessToMnemonic(state: State) -> Effect<Action> {
		.merge(state.accountRows.map {
			.send(.child(.account(
				id: $0.id,
				action: .internal(.checkAccountAccessToMnemonic)
			)))
		})
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .account(id, action: .delegate(delegateAction)):
			guard let accountRow = state.accountRows[id: id] else { return .none }
			let account = accountRow.account
			switch delegateAction {
			case .openDetails:
				state.destination = .accountDetails(.init(accountWithInfo: accountRow.accountWithInfo))
				return .none
			case .exportMnemonic:
				return exportMnemonic(controlling: account, state: &state)
			case .importMnemonics:
				return importMnemonics(state: &state)
			}

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .accountDetails(.delegate(.exportMnemonic(controlledAccount))):
			return dismissAccountDetails(then: .exportMnemonic(account: controlledAccount), &state)

		case .accountDetails(.delegate(.importMnemonics)):
			return dismissAccountDetails(then: .importMnemonic, &state)

		case .accountDetails(.delegate(.dismiss)):
			state.destination = nil
			return .none

		case let .exportMnemonic(.delegate(delegateAction)):
			state.destination = nil
			switch delegateAction {
			case .doneViewing:
				return checkAccountsAccessToMnemonic(state: state)

			case .notPersisted, .persistedMnemonicInKeychainOnly, .persistedNewFactorSourceInProfile:
				assertionFailure("Expected 'doneViewing' action")
				return .none
			}

		case let .importMnemonics(.delegate(delegateAction)):
			state.destination = nil
			switch delegateAction {
			case .finishedEarly: break
			case let .finishedImportingMnemonics(_, imported, notYetSavedNewMainBDFS):
				assert(notYetSavedNewMainBDFS == nil, "Discrepancy, new Main BDFS should already have been saved.")
				if !imported.isEmpty {
					return checkAccountsAccessToMnemonic(state: state)
				}
			}
			return .none

		default:
			return .none
		}
	}

	private func dismissAccountDetails(then internalAction: InternalAction, _ state: inout State) -> Effect<Action> {
		state.destination = nil
		return delayedMediumEffect(internal: internalAction)
	}

	private func importMnemonics(state: inout State) -> Effect<Action> {
		state.destination = .importMnemonics(.init())
		return .none
	}

	private func exportMnemonic(controlling account: Profile.Network.Account, state: inout State) -> Effect<Action> {
		exportMnemonic(
			controlling: account,
			onSuccess: {
				state.destination = .exportMnemonic(.export(
					$0,
					title: L10n.RevealSeedPhrase.title,
					context: .fromBackupPrompt
				))
			}
		)
	}

	private func loadShouldWriteDownPersonasSeedPhrase() -> Effect<Action> {
		.run { send in
			@Dependency(\.personasClient) var personasClient
			for try await shouldBackup in await personasClient.shouldWriteDownSeedPhraseForSomePersonaSequence() {
				guard !Task.isCancelled else { return }
				await send(.internal(.loadedShouldWriteDownPersonasSeedPhrase(shouldBackup)))
			}
		}
	}

	private func loadIsCurrencyAmountVisible() -> Effect<Action> {
		.run { send in
			for try await isCurrencyAmountVisible in await appPreferencesClient.appPreferenceUpdates().map(\.display.isCurrencyAmountVisible) {
				guard !Task.isCancelled else { return }
				await send(.internal(.loadIsCurrencyAmountVisible(isCurrencyAmountVisible)))
			}
		}
	}

	public func loadAccountsPortfolios() -> Effect<Action> {
		.run { send in
			for try await portfolios in await accountPortfoliosClient.portfoliosUpdates().debounce(for: .seconds(0.1)) {
				guard !Task.isCancelled else { return }

				await send(.internal(.loadedPortfolios(
					portfolios
				)))
			}
		}
	}
}

extension Home.State {
	public var accounts: IdentifiedArrayOf<Profile.Network.Account> {
		accountRows.map(\.account).asIdentifiable()
	}

	public var accountAddresses: [AccountAddress] {
		accounts.map(\.address)
	}
}
