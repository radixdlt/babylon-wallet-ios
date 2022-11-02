import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import AggregatedValueFeature
import Asset
import ComposableArchitecture
import CreateAccountFeature
import Foundation
import FungibleTokenListFeature
import IncomingConnectionRequestFromDappReviewFeature
import PasteboardClient
import TransactionSigningFeature

// MARK: - Home
public struct Home: ReducerProtocol {
	@Dependency(\.accountPortfolioFetcher) var accountPortfolioFetcher
	@Dependency(\.appSettingsClient) var appSettingsClient
	@Dependency(\.fungibleTokenListSorter) var fungibleTokenListSorter
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.openURL) var openURL

	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		Scope(state: \.header, action: /Action.header) {
			Reduce(
				Home.Header.reducer,
				environment: Home.Header.Environment()
			)
		}

		Scope(state: \.aggregatedValue, action: /Action.aggregatedValue) {
			Reduce(
				AggregatedValue.reducer,
				environment: AggregatedValue.Environment()
			)
		}

		Scope(state: \.visitHub, action: /Action.visitHub) {
			Reduce(
				Home.VisitHub.reducer,
				environment: Home.VisitHub.Environment()
			)
		}

		Scope(state: \.accountList, action: /Action.accountList) {
			Reduce(
				AccountList.reducer,
				environment: AccountList.Environment()
			)
		}

		.ifLet(\.accountDetails, action: /Action.accountDetails) {
			Reduce(
				AccountDetails.reducer,
				environment: AccountDetails.Environment()
			)
		}

		.ifLet(\.accountPreferences, action: /Action.accountPreferences) {
			Reduce(
				AccountPreferences.reducer,
				environment: AccountPreferences.Environment()
			)
		}

		.ifLet(\.transfer, action: /Action.transfer) {
			Reduce(
				AccountDetails.Transfer.reducer,
				environment: AccountDetails.Transfer.Environment()
			)
		}

		.ifLet(\.createAccount, action: /Action.createAccount) {
			CreateAccount()
		}

		#if DEBUG
			.ifLet(\.debugInitiatedConnectionRequest, action: /Action.debugInitiatedConnectionRequest) {
				IncomingConnectionRequestFromDappReview()
			}

			.ifLet(\.debugTransactionSigning, action: /Action.debugTransactionSigning) {
				TransactionSigning()
			}
		#endif

		Reduce(self.core)
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.user(.createAccountButtonTapped)):
			return .run { send in
				let accounts = try profileClient.getAccounts()
				await send(.internal(.coordinate(.createAccount(numberOfExistingAccounts: accounts.count))))
			}

		case let .internal(.coordinate(.createAccount(numberOfExistingAccounts))):
			state.createAccount = .init(
				numberOfExistingAccounts: numberOfExistingAccounts
			)
			return .none

		#if DEBUG
		case .internal(.user(.showDAppConnectionRequest)):
			state.debugInitiatedConnectionRequest = .init(incomingConnectionRequestFromDapp: .placeholder)
			return .none

		case .internal(.user(.showTransactionSigning)):
			state.debugTransactionSigning = .init(address: "123", transactionManifest: .mock)
			return .none
		#endif

		case .internal(.system(.viewDidAppear)):
			return .run { send in
				await send(.internal(.system(.loadAccountsAndSettings)))
			}

		case .internal(.system(.loadAccountsAndSettings)):
			return .run { send in
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
				let categories = fungibleTokenListSorter.sortTokens(accountPortfolio.fungibleTokenContainers)

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
				pasteboardClient.copyString(address.address)
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
			return .fireAndForget {
				await openURL(URL(string: "https://www.apple.com")!)
			}
		case .visitHub(.internal):
			return .none

		case .accountList(.coordinate(.fetchPortfolioForAccounts)):
			return .run { send in
				await send(.internal(.system(.loadAccountsAndSettings)))
			}

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
					try await accountPortfolioFetcher.fetchPortfolio([address])
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

		case let .createAccount(.coordinate(.failedToCreateNewAccount(reason: reason))):
			state.createAccount = nil
			print("Failed to create account: \(reason)")
			return .none

		case .transfer(.internal):
			return .none

		#if DEBUG
		case .debugInitiatedConnectionRequest(.internal(_)):
			return .none
		case .debugInitiatedConnectionRequest(.coordinate(.dismissIncomingConnectionRequest)):
			state.debugInitiatedConnectionRequest = nil
			return .none
		case .debugInitiatedConnectionRequest(.coordinate(_)):
			return .none
		case .debugInitiatedConnectionRequest(.chooseAccounts(_)):
			return .none
		#endif
		}
	}
}
