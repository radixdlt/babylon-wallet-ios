import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import AggregatedValueFeature
import Asset
import ComposableArchitecture
import CreateAccountFeature
import FungibleTokenListFeature
import IncomingConnectionRequestFromDappReviewFeature

#if os(iOS)
// FIXME: move to `UIApplicationClient` package!
import UIKit
#endif

public extension Home {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		Home.Header.reducer
			.pullback(
				state: \.header,
				action: /Home.Action.header,
				environment: { _ in Home.Header.Environment() }
			),

		AggregatedValue.reducer
			.pullback(
				state: \.aggregatedValue,
				action: /Home.Action.aggregatedValue,
				environment: { _ in AggregatedValue.Environment() }
			),

		Home.VisitHub.reducer
			.pullback(
				state: \.visitHub,
				action: /Home.Action.visitHub,
				environment: { _ in Home.VisitHub.Environment() }
			),

		AccountList.reducer
			.pullback(
				state: \.accountList,
				action: /Home.Action.accountList,
				environment: { _ in AccountList.Environment() }
			),

		AccountDetails.reducer
			.optional()
			.pullback(
				state: \.accountDetails,
				action: /Home.Action.accountDetails,
				environment: { _ in
					AccountDetails.Environment()
				}
			),

		AccountPreferences.reducer
			.optional()
			.pullback(
				state: \.accountPreferences,
				action: /Home.Action.accountPreferences,
				environment: { _ in
					AccountPreferences.Environment()
				}
			),

		AccountDetails.Transfer.reducer
			.optional()
			.pullback(
				state: \.transfer,
				action: /Home.Action.transfer,
				environment: { _ in
					AccountDetails.Transfer.Environment()
				}
			),

		// TODO: remove AnyReducer when migration to ReducerProtocol is complete
		AnyReducer { _ in
			CreateAccount()
		}
		.optional()
		.pullback(
			state: \.createAccount,
			action: /Home.Action.createAccount,
			environment: { $0 }
		),

		// commented out DEBUG because swift format replaces state with _
		// #if DEBUG

		// TODO: remove AnyReducer when migration to ReducerProtocol is complete
		AnyReducer { _ in
			IncomingConnectionRequestFromDappReview()
		}
		.optional()
		.pullback(
			state: \.connectionRequest,
			action: /Home.Action.debugInitiatedConnectionRequest,
			environment: { $0 }
		),
		// #endif

		Reducer { state, action, environment in

			switch action {
			case .internal(.user(.createAccountButtonTapped)):
				return .run { send in
					let accounts = try environment.profileClient.getAccounts()
					await send(.internal(.coordinate(.createAccount(numberOfExistingAccounts: accounts.count))))
				}

			// commented out DEBUG because swift format replaces state with _
			// #if DEBUG
			case .internal(.user(.showDAppConnectionRequest)):
				state.connectionRequest = .init(incomingConnectionRequestFromDapp: .placeholder)
				return .none
			// #endif

			case let .internal(.coordinate(.createAccount(numberOfExistingAccounts))):
				state.createAccount = .init(numberOfExistingAccounts: numberOfExistingAccounts)
				return .none

			case .internal(.system(.viewDidAppear)):
				return .run { send in
					await send(.internal(.system(.loadAccountsAndSettings)))
				}

			case .internal(.system(.loadAccountsAndSettings)):
				return .run { send in
					let accounts = try environment.profileClient.getAccounts()
					await send(.internal(.system(.accountsLoaded(accounts))))
					let settings = try await environment.appSettingsClient.loadSettings()
					await send(.internal(.system(.currencyLoaded(settings.currency))))
					await send(.internal(.system(.isCurrencyAmountVisibleLoaded(settings.isCurrencyAmountVisible))))
				}

			case let .internal(.system(.accountsLoaded(accounts))):
				state.accountList = .init(nonEmptyOrderedSetOfAccounts: accounts)
				return .none

			case let .internal(.system(.currencyLoaded(currency))):
				state.aggregatedValue.currency = currency
				state.accountList.accounts.forEach {
					state.accountList.accounts[id: $0.address]?.currency = currency
				}
				return .none

			case .internal(.system(.toggleIsCurrencyAmountVisible)):
				return .run { send in
					var isVisible = try await environment.appSettingsClient.loadSettings().isCurrencyAmountVisible
					isVisible.toggle()
					try await environment.appSettingsClient.saveIsCurrencyAmountVisible(isVisible)
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
//				state.aggregatedValue.value = totalPortfolio.compactMap(\.value.worth).reduce(0, +)

				// account list
				state.accountList.accounts.forEach {
//					state.accountList.accounts[id: $0.address]?.aggregatedValue = totalPortfolio[$0.address]?.worth
					let accountPortfolio = totalPortfolio[$0.address] ?? OwnedAssets.empty
					state.accountList.accounts[id: $0.address]?.portfolio = accountPortfolio
				}

				// account details
				if let details = state.accountDetails {
					// aggregated value
					let account = details.account
					let accountWorth = state.accountPortfolioDictionary[details.address]
//					state.accountDetails?.aggregatedValue.value = accountWorth?.worth

					// asset list
					let accountPortfolio = totalPortfolio[account.address] ?? OwnedAssets.empty
					let categories = environment.fungibleTokenListSorter.sortTokens(accountPortfolio.fungibleTokenContainers)

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

			case let .internal(.system(.copyAddress(address))):
				// TODO: display confirmation popup? discuss with po / designer
				return .run { _ in
					environment.pasteboardClient.copyString(address.address)
				}

			case let .internal(.system(.viewDidAppearActionFailed(reason: reason))):
				print(reason)
				return .none

			case let .internal(.system(.toggleIsCurrencyAmountVisibleFailed(reason: reason))):
				print(reason)
				return .none

			case .coordinate:
				return .none

			case .header(.coordinate(.displaySettings)):
				return Effect(value: .coordinate(.displaySettings))

			case .header(.internal):
				return .none

			case .aggregatedValue(.coordinate(.toggleIsCurrencyAmountVisible)):
				return Effect(value: .internal(.system(.toggleIsCurrencyAmountVisible)))

			case .aggregatedValue(.internal):
				return .none

			case .visitHub(.coordinate(.displayHub)):
				#if os(iOS)
				// FIXME: move to `UIApplicationClient` package!
				return .fireAndForget {
					UIApplication.shared.open(URL(string: "https://www.apple.com")!)
				}
				#else
				return .none
				#endif // os(iOS)

			case .visitHub(.internal):
				return .none

			case .accountList(.coordinate(.fetchPortfolioForAccounts)):
				return .run { send in
					let accounts = try environment.profileClient.getAccounts().rawValue.elements
					let addresses = accounts.map(\.address)
					await send(.internal(.system(.fetchPortfolioResult(TaskResult {
						try await environment.accountPortfolioFetcher.fetchPortfolio(addresses)
					}))))
				}

//			case let .internal(.system(.fetchPortfolioResult(.success(totalPortfolio)))):
//				return .run { send in
//					await send(.internal(.system(.accountPortfolioResult(.success(totalPortfolio)))))
//				}
			case let .internal(.system(.fetchPortfolioResult(.failure(error)))):
				print("⚠️ failed to fetch portfolio, error: \(String(describing: error))")
				return .none

			case let .accountList(.coordinate(.displayAccountDetails(account))):
				state.accountDetails = .init(for: account)
				return .none

			case let .accountList(.coordinate(.copyAddress(address))):
				return .run { send in
					await send(.internal(.system(.copyAddress(address.wrapAsAddress()))))
				}

			case .accountList:
				return .none

			case .accountPreferences(.coordinate(.dismissAccountPreferences)):
				state.accountPreferences = nil
				return .none

			case .accountPreferences(.internal):
				return .none

			case .accountDetails(.coordinate(.dismissAccountDetails)):
				state.accountDetails = nil
				return .none

			case .accountDetails(.internal):
				return .none

			case .accountDetails(.coordinate(.displayAccountPreferences)):
				state.accountPreferences = .init()
				return .none

			case let .accountDetails(.coordinate(.copyAddress(address))):
				return .run { send in
					await send(.internal(.system(.copyAddress(address.wrapAsAddress()))))
				}

			case .accountDetails(.coordinate(.displayTransfer)):
				state.transfer = .init()
				return .none

			case let .accountDetails(.coordinate(.refresh(address))):
				return .run { send in
					await send(.internal(.system(.accountPortfolioResult(TaskResult {
						try await environment.accountPortfolioFetcher.fetchPortfolio([address])
					}))))
				}

			case .accountDetails(.aggregatedValue(.internal(_))):
				return .none

			case .accountDetails(.aggregatedValue(.coordinate(.toggleIsCurrencyAmountVisible))):
				return Effect(value: .internal(.system(.toggleIsCurrencyAmountVisible)))

			case .accountDetails(.assets):
				return .none

			case .transfer(.coordinate(.dismissTransfer)):
				state.transfer = nil
				return .none

			case .createAccount(.internal):
				return .none

			case .createAccount(.coordinate(.dismissCreateAccount)):
				state.createAccount = nil
				return .none

			case .createAccount(.coordinate(.createdNewAccount(_))):
				state.createAccount = nil
				return .run { send in
					await send(.internal(.system(.loadAccountsAndSettings)))
				}

			case .transfer(.internal):
				return .none

			// commented out DEBUG because swift format replaces state with _
			// #if DEBUG
			case .debugInitiatedConnectionRequest(.internal(_)):
				return .none
			case .debugInitiatedConnectionRequest(.coordinate(.dismissIncomingConnectionRequest)):
				state.connectionRequest = nil
				return .none
			case .debugInitiatedConnectionRequest(.coordinate(_)):
				return .none
			case .debugInitiatedConnectionRequest(.chooseAccounts(_)):
				return .none
				// #endif
			}
		}
	)
}
