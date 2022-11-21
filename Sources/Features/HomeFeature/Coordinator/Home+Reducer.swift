import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import Asset
import Collections
import ComposableArchitecture
import CreateAccountFeature
import Foundation
import FungibleTokenListFeature
import IncomingConnectionRequestFromDappReviewFeature
import LegibleError
import P2PConnectivityClient
import PasteboardClient
import Profile
import SharedModels
import TransactionSigningFeature

// MARK: - Home
public struct Home: ReducerProtocol {
	@Dependency(\.accountPortfolioFetcher) var accountPortfolioFetcher
	@Dependency(\.appSettingsClient) var appSettingsClient
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.openURL) var openURL
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.header, action: /Action.child .. Action.ChildAction.header) {
			Home.Header()
		}

		accountListReducer()

		Reduce(self.core)
	}

	func accountListReducer() -> some ReducerProtocolOf<Self> {
		Scope(state: \.accountList, action: /Action.child .. Action.ChildAction.accountList) {
			AccountList()
		}
		.ifLet(\.accountDetails, action: /Action.child .. Action.ChildAction.accountDetails) {
			AccountDetails()
		}
		.ifLet(\.accountPreferences, action: /Action.child .. Action.ChildAction.accountPreferences) {
			AccountPreferences()
		}
		.ifLet(\.transfer, action: /Action.child .. Action.ChildAction.transfer) {
			AccountDetails.Transfer()
		}
		.ifLet(\.createAccount, action: /Action.child .. Action.ChildAction.createAccount) {
			CreateAccount()
		}
		.ifLet(\.chooseAccountRequestFromDapp, action: /Action.child .. Action.ChildAction.chooseAccountRequestFromDapp) {
			IncomingConnectionRequestFromDappReview()
		}
		.ifLet(\.transactionSigning, action: /Action.child .. Action.ChildAction.transactionSigning) {
			TransactionSigning()
		}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.createAccountButtonTapped)):
			return .run { send in
				let accounts = try profileClient.getAccounts()
				await send(.internal(.system(.createAccount(numberOfExistingAccounts: accounts.count))))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .internal(.system(.createAccount(numberOfExistingAccounts))):
			state.createAccount = .init(
				numberOfExistingAccounts: numberOfExistingAccounts
			)
			return .none

		case .internal(.view(.didAppear)):
			return loadAccountsConnectionsAndSettings()

		case let .internal(.system(.subscribeToRequestsFromP2PClientByID(ids))):
			return .run { send in
				await withThrowingTaskGroup(of: Void.self) { taskGroup in
					for id in ids {
						taskGroup.addTask {
							do {
								let requests = try await p2pConnectivityClient.getRequestsFromP2PClientAsyncSequence(id)
								for try await request in requests {
									await send(.internal(.system(.receiveRequestFromP2PClientResult(.success(request)))))
								}
							} catch {
								await send(.internal(.system(.receiveRequestFromP2PClientResult(.failure(error)))))
							}
						}
					}
				}
			}

		case let .internal(.system(.receiveRequestFromP2PClientResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.receiveRequestFromP2PClientResult(.success(requestFromP2P)))):
			state.unfinishedRequestsFromClient.queue(requestFromClient: requestFromP2P)

			guard state.handleRequest == nil else {
				// already handling a requests
				return .none
			}
			guard let itemToHandle = state.unfinishedRequestsFromClient.next() else {
				fatalError("We just queued a request, did it contain no RequestItems at all? This is undefined behaviour. Should we return an empty response here?")
			}
			return .run { send in
				await send(.internal(.system(.presentViewForP2PRequest(itemToHandle))))
			}

		case let .internal(.system(.connectionsLoadedResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.connectionsLoadedResult(.success(connections)))):
			let ids = OrderedSet(connections.map(\.id))
			return .run { send in
				await send(.internal(.system(.subscribeToRequestsFromP2PClientByID(ids))))
			}

		case let .internal(.system(.accountsLoadedResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.accountsLoadedResult(.success(accounts)))):
			state.accountList = .init(nonEmptyOrderedSetOfAccounts: accounts)
			return .run { send in
				await send(.internal(.system(.fetchPortfolioResult(TaskResult {
					try await accountPortfolioFetcher.fetchPortfolio(accounts.map(\.address))
				}))))
			}

		case let .internal(.system(.appSettingsLoadedResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.appSettingsLoadedResult(.success(appSettings)))):
			// FIXME: Replace currency with value from Profile!
			let currency = appSettings.currency
			state.accountList.accounts.forEach {
				state.accountList.accounts[id: $0.address]?.currency = currency
			}
			return .run { send in
				await send(.internal(.system(.isCurrencyAmountVisibleLoaded(appSettings.isCurrencyAmountVisible))))
			}

		case let .internal(.system(.isCurrencyAmountVisibleLoaded(isVisible))):
			// account list
			state.accountList.accounts.forEach {
				// TODO: replace hardcoded true value with isVisible value
				state.accountList.accounts[id: $0.address]?.isCurrencyAmountVisible = true
			}

			// account details
			state.accountDetails?.assets.fungibleTokenList.sections.forEach { section in
				section.assets.forEach { row in
					state.accountDetails?.assets.fungibleTokenList.sections[id: section.id]?.assets[id: row.id]?.isCurrencyAmountVisible = isVisible
				}
			}

			return .none

		case let .internal(.system(.fetchPortfolioResult(.success(totalPortfolio)))):
			state.accountPortfolioDictionary = totalPortfolio
			state.accountList.accounts.forEach {
				let accountPortfolio = totalPortfolio[$0.address] ?? OwnedAssets.empty
				state.accountList.accounts[id: $0.address]?.portfolio = accountPortfolio
			}

			// account details
			if let details = state.accountDetails {
				let account = details.account

				// asset list
				let accountPortfolio = totalPortfolio[account.address] ?? OwnedAssets.empty
				let categories = accountPortfolio.fungibleTokenContainers.sortedIntoCategories()

				state.accountDetails?.assets = .init(
					fungibleTokenList: .init(
						sections: .init(uniqueElements: categories.map { category in
							let rows = category.tokenContainers.map { container in FungibleTokenList.Row.State(container: container, currency: .usd, isCurrencyAmountVisible: true) }
							return FungibleTokenList.Section.State(id: category.type, assets: .init(uniqueElements: rows))
						})
					),
					nonFungibleTokenList: .init(
						rows: .init(uniqueElements: [accountPortfolio.nonFungibleTokenContainers].map {
							.init(containers: $0)
						})
					)
				)
			}

			return .none

		case let .internal(.system(.accountPortfolioResult(.success(accountPortfolio)))):
			guard let key = accountPortfolio.first?.key else { return .none }
			state.accountPortfolioDictionary[key] = accountPortfolio.first?.value
			return .run { [portfolio = state.accountPortfolioDictionary] send in
				await send(.internal(.system(.fetchPortfolioResult(.success(portfolio)))))
			}

		case let .internal(.system(.accountPortfolioResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .child(.header(.delegate(.displaySettings))):
			return .run { send in
				await send(.delegate(.displaySettings))
			}

		case .child(.accountList(.delegate(.fetchPortfolioForAccounts))):
			return loadAccountsConnectionsAndSettings()

		case let .internal(.system(.fetchPortfolioResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .child(.accountList(.delegate(.displayAccountDetails(account)))):
			state.accountDetails = .init(for: account)
			return .none

		case let .child(.accountList(.delegate(.copyAddress(address)))):
			return copyAddress(address)

		case .child(.accountPreferences(.delegate(.dismissAccountPreferences))):
			state.accountPreferences = nil
			return .none

		case .child(.accountDetails(.delegate(.dismissAccountDetails))):
			state.accountDetails = nil
			return .none

		case .child(.accountDetails(.delegate(.displayAccountPreferences))):
			state.accountPreferences = .init()
			return .none

		case let .child(.accountDetails(.delegate(.copyAddress(address)))):
			return copyAddress(address)

		case .child(.accountDetails(.delegate(.displayTransfer))):
			state.transfer = .init()
			return .none

		case let .child(.accountDetails(.delegate(.refresh(address)))):
			return .run { send in
				await send(.internal(.system(.accountPortfolioResult(TaskResult {
					try await accountPortfolioFetcher.fetchPortfolio([address])
				}))))
			}

		case .child(.transfer(.delegate(.dismissTransfer))):
			state.transfer = nil
			return .none

		case .child(.createAccount(.delegate(.dismissCreateAccount))):
			state.createAccount = nil
			return .none

		case .child(.createAccount(.delegate(.createdNewAccount))):
			state.createAccount = nil
			return loadAccountsConnectionsAndSettings()

		case .child(.createAccount(.delegate(.failedToCreateNewAccount))):
			state.createAccount = nil
			return .none

		case let .internal(.system(.presentViewForP2PRequest(requestItemToHandle))):
			state.handleRequest = .init(requestItemToHandle: requestItemToHandle)
			return .none

		case let .child(.chooseAccountRequestFromDapp(.delegate(.dismiss(dismissedRequestItem)))):
			return .run { send in
				await send(.internal(.system(.dismissed(dismissedRequestItem.parentRequest))))
			}

		case let .internal(.system(.dismissed(dismissedRequest))):
			state.handleRequest = nil
			state.unfinishedRequestsFromClient.dismiss(request: dismissedRequest)
			return presentViewForNextBufferedRequestFromBrowserIfNeeded(state: &state)

		case let .child(.chooseAccountRequestFromDapp(.delegate(.finishedChoosingAccounts(selectedAccounts, request)))):
			state.handleRequest = nil
			let accountAddresses: [P2P.ToDapp.WalletAccount] = selectedAccounts.map {
				.init(account: $0)
			}
			let responseItem = P2P.ToDapp.WalletResponseItem.ongoingAccountAddresses(.init(accountAddresses: .init(rawValue: accountAddresses)!))

			guard let responseContent = state.unfinishedRequestsFromClient.finish(
				.oneTimeAccountAddresses(request.requestItem), with: responseItem
			) else {
				return .run { send in
					await send(.internal(.system(.handleNextRequestItemIfNeeded)))
				}
			}

			let response = P2P.ResponseToClientByID(
				connectionID: request.parentRequest.client.id,
				responseToDapp: responseContent
			)

			return .run { send in
				await send(.internal(.system(.sendResponseBackToDappResult(
					TaskResult {
						try await p2pConnectivityClient.sendMessage(response)
					}
				))))
			}

		case .internal(.system(.handleNextRequestItemIfNeeded)):
			return presentViewForNextBufferedRequestFromBrowserIfNeeded(state: &state)

		case .internal(.system(.sendResponseBackToDappResult(.success(_)))):
			return presentViewForNextBufferedRequestFromBrowserIfNeeded(state: &state)

		case let .internal(.system(.sendResponseBackToDappResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .child(.transactionSigning(.delegate(.signedTXAndSubmittedToGateway(_, _)))):
			state.handleRequest = nil

			// FIXME: Betanet: once we have migrated to Hammunet we can use the EngineToolkit to read out required signeres to sign tx.
			errorQueue.schedule(
				NSError(domain: "Transaction signing disabled until app is Hammunet compatible. Once we have it in place we should respond back with TXID to dApp here.", code: 1337)
			)
			return .none

		case let .child(.transactionSigning(.delegate(.dismissed(dismissedRequestItem)))):
			return .run { send in
				await send(.internal(.system(.dismissed(dismissedRequestItem.parentRequest))))
			}

		case .child, .delegate:
			return .none
		}
	}

	func toggleCurrencyAmountVisible() -> EffectTask<Action> {
		.run { send in
			var isVisible = try await appSettingsClient.loadSettings().isCurrencyAmountVisible
			isVisible.toggle()
			try await appSettingsClient.saveIsCurrencyAmountVisible(isVisible)
			await send(.internal(.system(.isCurrencyAmountVisibleLoaded(isVisible))))
		}
	}

	func loadAccountsConnectionsAndSettings() -> EffectTask<Action> {
		.run { send in
			await send(.internal(.system(.accountsLoadedResult(
				TaskResult {
					try profileClient.getAccounts()
				}
			))))
			await send(.internal(.system(.appSettingsLoadedResult(
				TaskResult {
					try await appSettingsClient.loadSettings()
				}
			))))
			await send(.internal(.system(.connectionsLoadedResult(
				TaskResult {
					try await p2pConnectivityClient.getP2PClients()
				}
			))))
		}
	}

	func copyAddress(_ address: AccountAddress) -> EffectTask<Action> {
		// TODO: display confirmation popup? discuss with po / designer
		.run { _ in
			pasteboardClient.copyString(address.wrapAsAddress().address)
		}
	}

	func presentViewForNextBufferedRequestFromBrowserIfNeeded(state: inout State) -> EffectTask<Action> {
		guard let next = state.unfinishedRequestsFromClient.next() else {
			return .none
		}
		return .run { send in
			try await mainQueue.sleep(for: .seconds(1))
			await send(.internal(.system(.presentViewForP2PRequest(next))))
		}
	}
}
