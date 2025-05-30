import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - Home
struct Home: Sendable, FeatureReducer {
	private enum CancellableId: Hashable {
		case fetchAccountPortfolios
	}

	struct State: Sendable, Hashable {
		// MARK: - Components
		var carousel: CardCarousel.State = .init()

		var accountRows: IdentifiedArrayOf<Home.AccountRow.State> = []
		fileprivate var problems: [SecurityProblem] = []
		fileprivate var claims: ClaimsPerAccount = [:]

		var showFiatWorth: Bool = true

		var totalFiatWorth: Loadable<FiatWorth> = .idle

		// MARK: - Destination
		@PresentationState
		var destination: Destination.State? = nil {
			didSet {
				guard destination == nil else { return }
				showNextDestination()
			}
		}

		private var destinationsQueue: [Destination.State] = []

		init() {}

		mutating func addDestination(_ destination: Destination.State) {
			if self.destination == nil {
				self.destination = destination
			} else {
				destinationsQueue.append(destination)
			}
		}

		mutating func showNextDestination() {
			guard !destinationsQueue.isEmpty else { return }
			destination = destinationsQueue.removeFirst()
		}
	}

	enum ViewAction: Sendable, Equatable {
		case onFirstAppear
		case task
		case onDisappear
		case pullToRefreshStarted
		case createAccountButtonTapped
		case showFiatWorthToggled
	}

	enum InternalAction: Sendable, Equatable {
		case accountsLoadedResult(TaskResult<Accounts>)
		case currentGatewayChanged(to: Gateway)
		case shouldShowNPSSurvey(Bool)
		case accountsResourcesLoaded(Loadable<[OnLedgerEntity.OnLedgerAccount]>)
		case accountsFiatWorthLoaded([AccountAddress: Loadable<FiatWorth>])
		case showLinkConnectorIfNeeded
		case setSecurityProblems([SecurityProblem])
		case setAccountLockerClaims(ClaimsPerAccount)
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case carousel(CardCarousel.Action)
		case account(id: Home.AccountRow.State.ID, action: Home.AccountRow.Action)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case accountDetails(AccountDetails.State)
			case createAccount(CreateAccountCoordinator.State)
			case acknowledgeJailbreakAlert(AlertState<Action.AcknowledgeJailbreakAlert>)
			case npsSurvey(NPSSurvey.State)
			case relinkConnector(NewConnection.State)
			case securityCenter(SecurityCenter.State)
			case p2pLinks(P2PLinksFeature.State)
			case dAppsDirectory(DAppsDirectory.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case accountDetails(AccountDetails.Action)
			case createAccount(CreateAccountCoordinator.Action)
			case acknowledgeJailbreakAlert(AcknowledgeJailbreakAlert)
			case npsSurvey(NPSSurvey.Action)
			case relinkConnector(NewConnection.Action)
			case securityCenter(SecurityCenter.Action)
			case p2pLinks(P2PLinksFeature.Action)
			case dAppsDirectory(DAppsDirectory.Action)

			enum AcknowledgeJailbreakAlert: Sendable, Hashable {}
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.accountDetails, action: \.accountDetails) {
				AccountDetails()
			}
			Scope(state: \.createAccount, action: \.createAccount) {
				CreateAccountCoordinator()
			}
			Scope(state: \.npsSurvey, action: \.npsSurvey) {
				NPSSurvey()
			}
			Scope(state: \.relinkConnector, action: \.relinkConnector) {
				NewConnection()
			}
			Scope(state: \.securityCenter, action: \.securityCenter) {
				SecurityCenter()
			}
			Scope(state: \.p2pLinks, action: \.p2pLinks) {
				P2PLinksFeature()
			}
			Scope(state: \.dAppsDirectory, action: \.dAppsDirectory) {
				DAppsDirectory()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.iOSSecurityClient) var iOSSecurityClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.npsSurveyClient) var npsSurveyClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.securityCenterClient) var securityCenterClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.accountLockersClient) var accountLockersClient

	private let accountPortfoliosRefreshIntervalInSeconds = 300 // 5 minutes

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.carousel, action: \.child.carousel) {
			CardCarousel()
		}

		Reduce(core)
			.forEach(\.accountRows, action: /Action.child .. ChildAction.account) {
				Home.AccountRow()
			}
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstAppear:
			if iOSSecurityClient.isJailbroken() {
				state.addDestination(
					.acknowledgeJailbreakAlert(.init(
						title: .init(L10n.Splash.RootDetection.titleIOS),
						message: .init(L10n.Splash.RootDetection.messageIOS),
						buttons: [
							.cancel(.init(L10n.Splash.RootDetection.acknowledgeButton)),
						]
					))
				)
			}
			return .none

		case .task:
			return .run { send in
				for try await accounts in await accountsClient.accountsOnCurrentNetwork() {
					guard !Task.isCancelled else { return }
					await send(.internal(.accountsLoadedResult(.success(accounts))))
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
			.merge(with: loadGateways())
			.merge(with: loadNPSSurveyStatus())
			.merge(with: loadAccountResources())
			.merge(with: loadFiatValues())
			.merge(with: securityProblemsEffect())
			.merge(with: accountLockerClaimsEffect())
			.merge(with: delayedMediumEffect(for: .internal(.showLinkConnectorIfNeeded)))
			.merge(with: scheduleFetchAccountPortfoliosTimer(state))

		case .onDisappear:
			return .cancel(id: CancellableId.fetchAccountPortfolios)

		case .createAccountButtonTapped:
			state.destination = .createAccount(
				.init(config: .init(
					purpose: .newAccountFromHome
				))
			)
			return .none

		case .pullToRefreshStarted:
			accountLockersClient.forceRefresh()
			return fetchAccountPortfolios(state, forceRefresh: true)

		case .showFiatWorthToggled:
			return .run { _ in
				try await appPreferencesClient.toggleIsCurrencyAmountVisible()
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountsLoadedResult(.success(accounts)):
			guard accounts.elements != state.accounts.elements else {
				return .none
			}

			state.accountRows = accounts
				.map { account in
					// Create new Home.AccountRow.State only if it wasn't present before. Otherwise, we keep the old row
					// which probably has already loaded its resources & fiat worth.
					state.accountRows.first(where: { $0.id == account.address }) ?? .init(account: account, problems: state.problems)
				}
				.asIdentified()

			return fetchAccountPortfolios(state, forceRefresh: false)
				.merge(with: scheduleFetchAccountPortfoliosTimer(state))

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
				state.addDestination(.npsSurvey(.init()))
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

		case .showLinkConnectorIfNeeded:
			let purpose: NewConnectionApproval.State.Purpose? = if userDefaults.showRelinkConnectorsAfterProfileRestore {
				.approveRelinkAfterProfileRestore
			} else if userDefaults.showRelinkConnectorsAfterUpdate {
				.approveRelinkAfterUpdate
			} else {
				nil
			}
			if let purpose {
				state.addDestination(
					.relinkConnector(.init(root: .connectionApproval(.init(purpose: purpose))))
				)
			}
			return .none

		case let .setSecurityProblems(problems):
			state.problems = problems
			state.accountRows.mutateAll { row in
				row.securityProblemsConfig.update(problems: problems)
			}
			return .none

		case let .setAccountLockerClaims(claims):
			state.claims = claims
			state.accountRows.mutateAll { row in
				row.accountLockerClaims = claims[row.id] ?? []
			}
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .account(id, action: .delegate(delegateAction)):
			guard let accountRow = state.accountRows[id: id] else { return .none }
			switch delegateAction {
			case .openDetails:
				state.destination = .accountDetails(.init(accountWithInfo: accountRow.accountWithInfo, showFiatWorth: state.showFiatWorth))
				return .none
			case .openSecurityCenter:
				state.destination = .securityCenter(.init())
				return .none
			}

		case .carousel(.delegate(.addConnector)):
			state.destination = .p2pLinks(.init(destination: .newConnection(.init())))
			return .none

		default:
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .accountDetails(.delegate(.dismiss)):
			state.destination = nil
			return .none

		case let .npsSurvey(.delegate(.feedbackFilled(userFeedback))):
			state.destination = nil
			return uploadUserFeedback(userFeedback)

		case let .relinkConnector(.delegate(.newConnection(connectedClient))):
			state.destination = nil
			userDefaults.setShowRelinkConnectorsAfterProfileRestore(false)
			userDefaults.setShowRelinkConnectorsAfterUpdate(false)
			return .run { _ in
				try await radixConnectClient.updateOrAddP2PLink(connectedClient)
			} catch: { error, _ in
				loggerGlobal.error("Failed P2PLink, error \(error)")
				errorQueue.schedule(error)
			}

		default:
			return .none
		}
	}

	func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		var effect: Effect<Action>?

		switch state.destination {
		case .npsSurvey:
			effect = uploadUserFeedback(nil)
		case .relinkConnector:
			userDefaults.setShowRelinkConnectorsAfterProfileRestore(false)
			userDefaults.setShowRelinkConnectorsAfterUpdate(false)
		default:
			break
		}

		state.showNextDestination()
		return effect ?? .none
	}

	func loadGateways() -> Effect<Action> {
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
			for try await accountResources in accountPortfoliosClient
				.portfolioUpdates()
				.map({ updates in updates.map { update in update.map(\.account) } })
				.removeDuplicates()
			{
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

	private func securityProblemsEffect() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems() {
				guard !Task.isCancelled else { return }
				await send(.internal(.setSecurityProblems(problems)))
			}
		}
	}

	private func fetchAccountPortfolios(_ state: State, forceRefresh: Bool) -> Effect<Action> {
		.run { [accountAddresses = state.accountAddresses] _ in
			_ = try await accountPortfoliosClient.fetchAccountPortfolios(accountAddresses, forceRefresh)
			await accountPortfoliosClient.syncAccountsDeletedOnLedger()
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	private func scheduleFetchAccountPortfoliosTimer(_ state: State) -> Effect<Action> {
		.run { _ in
			for await _ in clock.timer(interval: .seconds(accountPortfoliosRefreshIntervalInSeconds)) {
				guard !Task.isCancelled else { return }
				_ = try? await accountPortfoliosClient.fetchAccountPortfolios(state.accountAddresses, true)
				await accountPortfoliosClient.syncAccountsDeletedOnLedger()
			}
		}
		.cancellable(id: CancellableId.fetchAccountPortfolios, cancelInFlight: true)
	}

	private func accountLockerClaimsEffect() -> Effect<Action> {
		.run { send in
			for try await claims in await accountLockersClient.claims() {
				guard !Task.isCancelled else { return }
				await send(.internal(.setAccountLockerClaims(claims)))
			}
		}
	}
}

extension Home.State {
	var accounts: IdentifiedArrayOf<Account> {
		accountRows.map(\.account).asIdentified()
	}

	var accountAddresses: [AccountAddress] {
		accounts.map(\.address)
	}
}
