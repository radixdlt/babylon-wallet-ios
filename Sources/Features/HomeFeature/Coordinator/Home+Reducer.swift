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
import GrantDappWalletAccessFeature
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
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.createAccountButtonTapped)):
			return .run { send in
				let accounts = try await profileClient.getAccounts()
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
			return loadAccountsAndSettings()

		case .internal(.view(.pullToRefreshStarted)):
			return .run { send in
				await send(.child(.accountList(.view(.viewAppeared))))
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
				let accountPortfolio = totalPortfolio[$0.address] ?? AccountPortfolio.empty
				state.accountList.accounts[id: $0.address]?.portfolio = accountPortfolio
			}

			// account details
			if let details = state.accountDetails {
				let account = details.account

				// asset list
				let accountPortfolio = totalPortfolio[account.address] ?? AccountPortfolio.empty
				let categories = accountPortfolio.fungibleTokenContainers.elements.sortedIntoCategories()

				state.accountDetails?.assets = .init(
					fungibleTokenList: .init(
						sections: .init(uniqueElements: categories.map { category in
							let rows = category.tokenContainers.map { container in FungibleTokenList.Row.State(container: container, currency: .usd, isCurrencyAmountVisible: true) }
							return FungibleTokenList.Section.State(id: category.type, assets: .init(uniqueElements: rows))
						})
					),
					nonFungibleTokenList: .init(
						rows: .init(uniqueElements: [accountPortfolio.nonFungibleTokenContainers.elements].map {
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
			return loadAccountsAndSettings()

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
			return loadAccountsAndSettings()

		case .child(.createAccount(.delegate(.failedToCreateNewAccount))):
			state.createAccount = nil
			return .none

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

	func loadAccountsAndSettings() -> EffectTask<Action> {
		.run { send in
			await loadAccountsAndSendAction(send)
			await loadSettingsAndSendAction(send)
		}
	}

	func loadAccounts() -> EffectTask<Action> {
		.run { send in
			await loadAccountsAndSendAction(send)
		}
	}

	@Sendable
	func loadAccountsAndSendAction(_ send: Send<Action>) async {
		await send(.internal(.system(.accountsLoadedResult(
			TaskResult {
				try await profileClient.getAccounts()
			}
		))))
	}

	@Sendable
	func loadSettingsAndSendAction(_ send: Send<Action>) async {
		await send(.internal(.system(.appSettingsLoadedResult(
			TaskResult {
				try await appSettingsClient.loadSettings()
			}
		))))
	}

	func copyAddress(_ address: AccountAddress) -> EffectTask<Action> {
		// TODO: display confirmation popup? discuss with po / designer
		.run { _ in
			pasteboardClient.copyString(address.wrapAsAddress().address)
		}
	}
}
