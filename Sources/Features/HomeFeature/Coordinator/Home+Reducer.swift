import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import AggregatedValueFeature
import Asset
import BrowserExtensionsConnectivityClient
import Collections
import ComposableArchitecture
import CreateAccountFeature
import Foundation
import FungibleTokenListFeature
import IncomingConnectionRequestFromDappReviewFeature
import PasteboardClient
import Profile
import TransactionSigningFeature

// MARK: - Home
public struct Home: ReducerProtocol {
	@Dependency(\.accountPortfolioFetcher) var accountPortfolioFetcher
	@Dependency(\.appSettingsClient) var appSettingsClient
	@Dependency(\.browserExtensionsConnectivityClient) var browserExtensionsConnectivityClient
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.openURL) var openURL
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		Scope(state: \.header, action: /Action.child .. Action.ChildAction.header) {
			Reduce(
				Home.Header.reducer,
				environment: Home.Header.Environment()
			)
		}

		Scope(state: \.aggregatedValue, action: /Action.child .. Action.ChildAction.aggregatedValue) {
			Reduce(
				AggregatedValue.reducer,
				environment: AggregatedValue.Environment()
			)
		}

		Scope(state: \.visitHub, action: /Action.child .. Action.ChildAction.visitHub) {
			Reduce(
				Home.VisitHub.reducer,
				environment: Home.VisitHub.Environment()
			)
		}

		accountListReducer()

		Reduce(self.core)
	}

	func accountListReducer() -> some ReducerProtocol<State, Action> {
		Scope(state: \.accountList, action: /Action.child .. Action.ChildAction.accountList) {
			Reduce(
				AccountList.reducer,
				environment: AccountList.Environment()
			)
		}
		.ifLet(\.accountDetails, action: /Action.child .. Action.ChildAction.accountDetails) {
			Reduce(
				AccountDetails.reducer,
				environment: AccountDetails.Environment()
			)
		}
		.ifLet(\.accountPreferences, action: /Action.child .. Action.ChildAction.accountPreferences) {
			Reduce(
				AccountPreferences.reducer,
				environment: AccountPreferences.Environment()
			)
		}
		.ifLet(\.transfer, action: /Action.child .. Action.ChildAction.transfer) {
			Reduce(
				AccountDetails.Transfer.reducer,
				environment: AccountDetails.Transfer.Environment()
			)
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
			}

		case let .internal(.system(.createAccount(numberOfExistingAccounts))):
			state.createAccount = .init(
				numberOfExistingAccounts: numberOfExistingAccounts
			)
			return .none

		case .internal(.view(.didAppear)):
			return loadAccountsConnectionsAndSettings()

		case let .internal(.system(.subscribeToIncomingMessagesFromDappsByBrowserConnectionIDs(ids))):
			return .run { send in
				await withThrowingTaskGroup(of: Void.self) { taskGroup in
					for id in ids {
						taskGroup.addTask {
							do {
								let incomingMsgs = try await browserExtensionsConnectivityClient.getIncomingMessageAsyncSequence(id)
								for try await incomingMsg in incomingMsgs {
									await send(.internal(.system(.receiveRequestMessageFromDappResult(
										TaskResult.success(incomingMsg)
									))))
								}
							} catch {
								await send(.internal(.system(.receiveRequestMessageFromDappResult(
									TaskResult.failure(error)
								))))
							}
						}
					}
				}
			}

		case let .internal(.system(.receiveRequestMessageFromDappResult(.failure(error)))):
			print("Failed to receive message from dApp, error: \(String(describing: error))")
			return .none

		case let .internal(.system(.connectionsLoadedResult(.failure(error)))):
			print("Failed to load connections, error: \(String(describing: error))")
			return .none

		case let .internal(.system(.connectionsLoadedResult(.success(connections)))):
			let ids = OrderedSet(connections.map(\.id))
			return .run { send in
				await send(.internal(.system(.subscribeToIncomingMessagesFromDappsByBrowserConnectionIDs(ids))))
			}

		case let .internal(.system(.accountsLoadedResult(.failure(error)))):
			print("Failed to load accounts, error: \(String(describing: error))")
			return .none

		case let .internal(.system(.accountsLoadedResult(.success(accounts)))):
			state.accountList = .init(nonEmptyOrderedSetOfAccounts: accounts)
			return .run { send in
				await send(.internal(.system(.fetchPortfolioResult(TaskResult {
					try await accountPortfolioFetcher.fetchPortfolio(accounts.map(\.address))
				}))))
			}

		case let .internal(.system(.appSettingsLoadedResult(.failure(error)))):
			print("Failed to load appSettings, error: \(String(describing: error))")
			return .none

		case let .internal(.system(.appSettingsLoadedResult(.success(appSettings)))):
			// FIXME: Replace currency with value from Profile!
			let currency = appSettings.currency
			state.aggregatedValue.currency = currency
			state.accountList.accounts.forEach {
				state.accountList.accounts[id: $0.address]?.currency = currency
			}
			return .run { send in
				await send(.internal(.system(.isCurrencyAmountVisibleLoaded(appSettings.isCurrencyAmountVisible))))
			}

		case .internal(.system(.toggleIsCurrencyAmountVisible)):
			return .run { send in
				var isVisible = try await appSettingsClient.loadSettings().isCurrencyAmountVisible
				isVisible.toggle()
				try await appSettingsClient.saveIsCurrencyAmountVisible(isVisible)
				await send(.internal(.system(.isCurrencyAmountVisibleLoaded(isVisible))))
			}

		case let .internal(.system(.isCurrencyAmountVisibleLoaded(isVisible))):
			// aggregated value
			state.aggregatedValue.isCurrencyAmountVisible = isVisible

			// account list
			state.accountList.accounts.forEach {
				state.accountList.accounts[id: $0.address]?.isCurrencyAmountVisible = isVisible
			}

			// account details
			state.accountDetails?.aggregatedValue.isCurrencyAmountVisible = isVisible
			state.accountDetails?.assets.fungibleTokenList.sections.forEach { section in
				section.assets.forEach { row in
					state.accountDetails?.assets.fungibleTokenList.sections[id: section.id]?.assets[id: row.id]?.isCurrencyAmountVisible = isVisible
				}
			}

			return .none

		case let .internal(.system(.fetchPortfolioResult(.success(totalPortfolio)))):
			state.accountPortfolioDictionary = totalPortfolio

			// aggregated value
			//            state.aggregatedValue.value = totalPortfolio.compactMap(\.value.worth).reduce(0, +)

			// account list
			state.accountList.accounts.forEach {
				//                state.accountList.accounts[id: $0.address]?.aggregatedValue = totalPortfolio[$0.address]?.worth
				let accountPortfolio = totalPortfolio[$0.address] ?? OwnedAssets.empty
				state.accountList.accounts[id: $0.address]?.portfolio = accountPortfolio
			}

			// account details
			if let details = state.accountDetails {
				// aggregated value
				let account = details.account
				// let accountWorth = state.accountPortfolioDictionary[details.address]
				//                state.accountDetails?.aggregatedValue.value = accountWorth?.worth

				// asset list
				let accountPortfolio = totalPortfolio[account.address] ?? OwnedAssets.empty
				let categories = accountPortfolio.fungibleTokenContainers.sortedIntoCategories()

				state.accountDetails?.assets = .init(
					fungibleTokenList: .init(
						sections: .init(uniqueElements: categories.map { category in
							let rows = category.tokenContainers.map { container in FungibleTokenList.Row.State(container: container, currency: details.aggregatedValue.currency, isCurrencyAmountVisible: details.aggregatedValue.isCurrencyAmountVisible) }
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
			print("⚠️ failed to fetch accout portfolio, error: \(String(describing: error))")
			return .none

		case let .internal(.system(.viewDidAppearActionFailed(reason: reason))):
			print(reason)
			return .none

		case let .internal(.system(.toggleIsCurrencyAmountVisibleFailed(reason: reason))):
			print(reason)
			return .none

		case .child(.header(.coordinate(.displaySettings))):
			return .run { send in await send(.delegate(.displaySettings)) }

		case .child(.aggregatedValue(.coordinate(.toggleIsCurrencyAmountVisible))):
			return .run { send in await send(.internal(.system(.toggleIsCurrencyAmountVisible))) }

		case .child(.visitHub(.coordinate(.displayHub))):
			return .fireAndForget {
				await openURL(URL(string: "https://www.apple.com")!)
			}

		case .child(.accountList(.coordinate(.fetchPortfolioForAccounts))):
			return loadAccountsConnectionsAndSettings()

		case let .internal(.system(.fetchPortfolioResult(.failure(error)))):
			print("⚠️ failed to fetch portfolio, error: \(String(describing: error))")
			return .none

		case let .child(.accountList(.coordinate(.displayAccountDetails(account)))):
			state.accountDetails = .init(for: account)
			return .none

		case let .child(.accountList(.coordinate(.copyAddress(address)))):
			return copyAddress(address)

		case .child(.accountPreferences(.coordinate(.dismissAccountPreferences))):
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

		case .child(.accountDetails(.child(.aggregatedValue(.coordinate(.toggleIsCurrencyAmountVisible))))):
			return Effect(value: .internal(.system(.toggleIsCurrencyAmountVisible)))

		case .child(.transfer(.delegate(.dismissTransfer))):
			state.transfer = nil
			return .none

		case .child(.createAccount(.coordinate(.dismissCreateAccount))):
			state.createAccount = nil
			return .none

		case .child(.createAccount(.coordinate(.createdNewAccount))):
			state.createAccount = nil
			return loadAccountsConnectionsAndSettings()

		case let .child(.createAccount(.coordinate(.failedToCreateNewAccount(reason: reason)))):
			state.createAccount = nil
			print("Failed to create account: \(reason)")
			return .none

		case .internal(.system(.presentViewForNextBufferedRequestFromBrowserIfNeeded)):

			guard let next = state.unhandledReceivedMessages.first else {
				return .none
			}
			state.unhandledReceivedMessages.removeFirst()

			return .run { send in
				try await mainQueue.sleep(for: .seconds(1))
				await send(.internal(.system(.presentViewForRequestFromBrowser(next))))
			}

		case let .internal(.system(.receiveRequestMessageFromDappResult(.success(incomingMessageFromBrowser)))):
			return .run { send in
				await send(.internal(.system(.presentViewForRequestFromBrowser(incomingMessageFromBrowser))))
			}

		case let .internal(.system(.presentViewForRequestFromBrowser(incomingRequestFromBrowser))):

			switch incomingRequestFromBrowser.payload {
			case let .accountAddresses(accountAddressRequest):
				if state.chooseAccountRequestFromDapp == nil {
					state.chooseAccountRequestFromDapp = IncomingConnectionRequestFromDappReview.State(
						incomingMessageFromBrowser: incomingRequestFromBrowser,
						incomingConnectionRequestFromDapp: .init(addressRequest: accountAddressRequest, from: incomingRequestFromBrowser.requestMethodWalletRequest)
					)
				} else {
					// Buffer
					state.unhandledReceivedMessages.append(incomingRequestFromBrowser)
				}
			case let .signTXRequest(signTXRequest):
				if state.transactionSigning == nil {
					// if `state.chooseAccountRequestFromDapp` is non nil, this will present SignTX view
					// on top of chooseAccountsView...
					state.transactionSigning = .init(
						incomingMessageFromBrowser: incomingRequestFromBrowser,
						addressOfSigner: signTXRequest.accountAddress,
						transactionManifest: signTXRequest.transactionManifest
					)
				} else {
					// Buffer
					state.unhandledReceivedMessages.append(incomingRequestFromBrowser)
				}
			}
			return .none

		case .child(.chooseAccountRequestFromDapp(.delegate(.dismiss))):
			state.chooseAccountRequestFromDapp = nil
			return .run { send in
				await send(.internal(.system(.presentViewForNextBufferedRequestFromBrowserIfNeeded)))
			}

		case let .child(.chooseAccountRequestFromDapp(.delegate(.finishedChoosingAccounts(selectedAccounts, incomingMessageFromBrowser)))):
			state.chooseAccountRequestFromDapp = nil
			let accountAddresses: [RequestMethodWalletResponse.AccountAddressesRequestMethodWalletResponse.AccountAddress] = selectedAccounts.map {
				.init(address: $0.address.address, label: $0.displayName ?? "AccountIndex: \($0.index)")
			}
			let response = RequestMethodWalletResponse(
				method: .request,
				requestId: incomingMessageFromBrowser.requestMethodWalletRequest.requestId,
				payload: [
					.accountAddresses(
						.init(
							addresses: accountAddresses
						)
					),
				]
			)
			return .run { send in
				await send(.internal(.system(.sendResponseBackToDapp(incomingMessageFromBrowser.browserExtensionConnection.id, response))))
			}

		case let .internal(.system(.sendResponseBackToDapp(browserConnectionID, response))):
			return .run { send in
				await send(.internal(.system(.sendResponseBackToDappResult(
					TaskResult {
						let outgoingMessage = MessageToDappRequest(
							browserExtensionConnectionID: browserConnectionID,
							requestMethodWalletResponse: response
						)

						return try await browserExtensionsConnectivityClient
							.sendMessage(outgoingMessage)
					}
				))))
			}

		case .internal(.system(.sendResponseBackToDappResult(.success(_)))):
			return .run { send in
				await send(.internal(.system(.presentViewForNextBufferedRequestFromBrowserIfNeeded)))
			}

		case let .internal(.system(.sendResponseBackToDappResult(.failure(error)))):
			print("Failed to send response back over webRTC, error: \(String(describing: error))")
			return .none

		case let .child(.transactionSigning(.delegate(.signedTXAndSubmittedToGateway(txID, incomingMessageFromBrowser)))):
			state.transactionSigning = nil
			let response = RequestMethodWalletResponse(
				method: .request,
				requestId: incomingMessageFromBrowser.requestMethodWalletRequest.requestId,
				payload: [
					.signTXRequest(.init(transactionIntentHash: txID)),
				]
			)
			return .run { send in
				await send(.internal(.system(.sendResponseBackToDapp(incomingMessageFromBrowser.browserExtensionConnection.id, response))))
			}

		case .child(.transactionSigning(.delegate(.dismissView))):
			state.transactionSigning = nil
			return .run { send in
				await send(.internal(.system(.presentViewForNextBufferedRequestFromBrowserIfNeeded)))
			}

		case .child, .delegate:
			return .none
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
					try await browserExtensionsConnectivityClient.getBrowserExtensionConnections()
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
}
