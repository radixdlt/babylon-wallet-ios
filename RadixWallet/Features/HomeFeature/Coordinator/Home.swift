import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - Home
public struct Home: Sendable, FeatureReducer {
	public static let radixBannerURL = URL(string: "https://wallet.radixdlt.com/?wallet=downloaded")!

	public struct State: Sendable, Hashable {
		// MARK: - Components
		public var accountRows: IdentifiedArrayOf<Home.AccountRow.State> = []
		public var shouldWriteDownPersonasSeedPhrase: Bool = false

		public var showRadixBanner: Bool = false
		public var showFiatWorth: Bool = true

		public var totalFiatWorth: Loadable<FiatWorth> = .idle

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
		case accountsLoadedResult(TaskResult<Sargon.Accounts>)
		case exportMnemonic(account: Sargon.Account)
		case importMnemonic
		case loadedShouldWriteDownPersonasSeedPhrase(Bool)
		case currentGatewayChanged(to: Gateway)
		case shouldShowNPSSurvey(Bool)
		case accountsResourcesLoaded(Loadable<[OnLedgerEntity.Account]>)
		case accountsFiatWorthLoaded([AccountAddress: Loadable<FiatWorth>])
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
			case npsSurvey(NPSSurvey.State)
		}

		public enum Action: Sendable, Equatable {
			case accountDetails(AccountDetails.Action)
			case createAccount(CreateAccountCoordinator.Action)
			case importMnemonics(ImportMnemonicsFlowCoordinator.Action)
			case exportMnemonic(ExportMnemonic.Action)
			case acknowledgeJailbreakAlert(AcknowledgeJailbreakAlert)
			case npsSurvey(NPSSurvey.Action)

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
			Scope(state: /State.npsSurvey, action: /Action.npsSurvey) {
				NPSSurvey()
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
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.npsSurveyClient) var npsSurveyClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient

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
			return .none

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
			.merge(with: loadGateways())
			.merge(with: loadNPSSurveyStatus())
			.merge(with: loadAccountResources())
			.merge(with: loadFiatValues())

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
			return .run { _ in
				try await appPreferencesClient.toggleIsCurrencyAmountVisible()
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountsLoadedResult(.success(accounts)):
			guard accounts.elements != state.accounts.elements else {
				return .none
			}

			state.accountRows = accounts.map { Home.AccountRow.State(account: $0) }.asIdentified()

			return .run { [addresses = state.accountAddresses] _ in
				_ = try await accountPortfoliosClient.fetchAccountPortfolios(addresses, false)
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
			.merge(with: checkAccountsAccessToMnemonic(state: state))

		case let .accountsLoadedResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .accountsResourcesLoaded(accountsResources):
			state.accountRows.mutateAll { row in
				if let accountResources = accountsResources.first(where: { $0.address == row.id }).unwrap() {
					row.accountWithResources.refresh(from: accountResources)
				}
			}
			return .none

		case let .loadedShouldWriteDownPersonasSeedPhrase(shouldBackup):
			state.shouldWriteDownPersonasSeedPhrase = shouldBackup
			return .none

		case let .exportMnemonic(account):
			return exportMnemonic(controlling: account, state: &state)

		case .importMnemonic:
			return importMnemonics(state: &state)

		case let .currentGatewayChanged(gateway):
			#if DEBUG
			state.showFiatWorth = true
			#else
			state.showFiatWorth = gateway == .mainnet
			state.accountRows.mutateAll { rowState in
				rowState.showFiatWorth = state.showFiatWorth
			}
			#endif
			return .none
		case let .shouldShowNPSSurvey(shouldShow):
			if shouldShow {
				state.destination = .npsSurvey(.init())
			}
			return .none
		case let .accountsFiatWorthLoaded(fiatWorths):
			state.accountRows.mutateAll {
				if let fiatWorth = fiatWorths[$0.id] {
					$0.totalFiatWorth.refresh(from: fiatWorth)
				}
			}
			state.totalFiatWorth = state.accountRows.map(\.totalFiatWorth).reduce(+) ?? .loading
			return .none
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
				state.destination = .accountDetails(.init(accountWithInfo: accountRow.accountWithInfo, showFiatWorth: state.showFiatWorth))
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

		case let .npsSurvey(.delegate(.feedbackFilled(userFeedback))):
			state.destination = nil
			return uploadUserFeedback(userFeedback)

		default:
			return .none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		if case .npsSurvey = state.destination {
			return uploadUserFeedback(nil)
		}
		return .none
	}

	private func dismissAccountDetails(then internalAction: InternalAction, _ state: inout State) -> Effect<Action> {
		state.destination = nil
		return delayedMediumEffect(internal: internalAction)
	}

	private func importMnemonics(state: inout State) -> Effect<Action> {
		state.destination = .importMnemonics(.init())
		return .none
	}

	private func exportMnemonic(controlling account: Sargon.Account, state: inout State) -> Effect<Action> {
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

	public func loadGateways() -> Effect<Action> {
		.run { send in
			for try await gateway in await gatewaysClient.currentGatewayValues() {
				guard !Task.isCancelled else { return }
				await send(.internal(.currentGatewayChanged(to: gateway)))
			}
		}
	}

	private func loadNPSSurveyStatus() -> Effect<Action> {
		.run { send in
			for try await shouldAsk in await npsSurveyClient.shouldAskForUserFeedback() {
				guard !Task.isCancelled else { return }
				await send(.internal(.shouldShowNPSSurvey(shouldAsk)))
			}
		}
	}

	private func uploadUserFeedback(_ feedback: NPSSurveyClient.UserFeedback?) -> Effect<Action> {
		overlayWindowClient.scheduleHUD(.thankYou)

		return .run { _ in
			await npsSurveyClient.uploadUserFeedback(feedback)
		}
	}

	private func loadAccountResources() -> Effect<Action> {
		.run { send in
			for try await accountResources in accountPortfoliosClient.portfolioUpdates().map { $0.map { $0.map(\.account) } }.removeDuplicates() {
				guard !Task.isCancelled else { return }
				await send(.internal(.accountsResourcesLoaded(accountResources)))
			}
		}
	}

	private func loadFiatValues() -> Effect<Action> {
		.run { send in
			let accountsTotalFiatWorth = accountPortfoliosClient.portfolioUpdates()
				.compactMap { portfoliosLoadable in
					portfoliosLoadable.wrappedValue?.reduce(into: [AccountAddress: Loadable<FiatWorth>]()) { partialResult, portfolio in
						partialResult[portfolio.account.address] = portfolio.totalFiatWorth
					}
				}
				.filter {
					// All items should load
					if let aggregated = Array($0.values).reduce(+), aggregated.didLoad {
						return true
					}
					return false
				}

			for try await accountsTotalFiatWorth in accountsTotalFiatWorth.removeDuplicates() {
				guard !Task.isCancelled else { return }
				await send(.internal(.accountsFiatWorthLoaded(accountsTotalFiatWorth)))
			}
		}
	}
}

extension Home.State {
	public var accounts: IdentifiedArrayOf<Sargon.Account> {
		accountRows.map(\.account).asIdentified()
	}

	public var accountAddresses: [AccountAddress] {
		accounts.map(\.address)
	}
}
