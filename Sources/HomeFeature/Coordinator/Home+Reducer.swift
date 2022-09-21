import AccountDetailsFeature
import AccountListFeature
import AccountPreferencesFeature
import AccountWorthFetcher
import AggregatedValueFeature
import AssetListFeature
import ComposableArchitecture
import CreateAccountFeature

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

		CreateAccount.reducer
			.optional()
			.pullback(
				state: \.createAccount,
				action: /Home.Action.createAccount,
				environment: { _ in
					CreateAccount.Environment()
				}
			),

		Reducer { state, action, environment in
			switch action {
			case .internal(.user(.createAccountButtonTapped)):
				state.createAccount = .init()
				return .none

			case .internal(.system(.viewDidAppear)):
				return .run { send in
					let settings = try await environment.appSettingsClient.loadSettings()
					await send(.internal(.system(.currencyLoaded(settings.currency))))
					await send(.internal(.system(.isCurrencyAmountVisibleLoaded(settings.isCurrencyAmountVisible))))
				}

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
				state.accountDetails?.assetList.sections.forEach { section in
					section.assets.forEach { row in
						state.accountDetails?.assetList.sections[id: section.id]?.assets[id: row.id]?.isCurrencyAmountVisible = isVisible
					}
				}

				return .none

			case let .internal(.system(.totalWorthLoaded(totalWorth))):
				state.accountsWorthDictionary = totalWorth

				// aggregated value
				state.aggregatedValue.value = totalWorth.compactMap(\.value.worth).reduce(0, +)

				// account list
				state.accountList.accounts.forEach {
					state.accountList.accounts[id: $0.address]?.aggregatedValue = totalWorth[$0.address]?.worth
					let tokenContainers = totalWorth[$0.address]?.tokenContainers ?? []
					state.accountList.accounts[id: $0.address]?.tokenContainers = tokenContainers
				}

				// account details
				if let details = state.accountDetails {
					// aggregated value
					let account = details.account
					let accountWorth = state.accountsWorthDictionary[details.address]
					state.accountDetails?.aggregatedValue.value = accountWorth?.worth

					// asset list
					let containers = totalWorth[account.address]?.tokenContainers ?? []
					let categories = environment.assetListSorter.sortTokens(containers)

					state.accountDetails?.assetList = .init(
						sections: .init(uniqueElements: categories.map { category in
							let rows = category.tokenContainers.map { container in AssetList.Row.State(tokenContainer: container, currency: details.aggregatedValue.currency, isCurrencyAmountVisible: details.aggregatedValue.isCurrencyAmountVisible) }
							return AssetList.Section.State(id: category.type, assets: .init(uniqueElements: rows))
						})
					)
				}

				return .none

			case let .internal(.system(.accountWorthLoaded(accountWorth))):
				guard let key = accountWorth.first?.key else { return .none }
				state.accountsWorthDictionary[key] = accountWorth.first?.value
				return Effect(value: .internal(.system(.totalWorthLoaded(state.accountsWorthDictionary))))

			case let .internal(.system(.copyAddress(address))):
				// TODO: display confirmation popup? discuss with po / designer
				return .run { _ in
					environment.pasteboardClient.copyString(address)
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

			case .accountList(.coordinate(.loadAccounts)):
				return .run { [state = state] send in
					let addresses = state.wallet.profile.accounts.map(\.address)
					let totalWorth = try await environment.accountWorthFetcher.fetchWorth(addresses)
					await send(.internal(.system(.totalWorthLoaded(totalWorth))))
				}

			case let .accountList(.coordinate(.displayAccountDetails(account))):
				state.accountDetails = .init(for: account)
				return .none

			case let .accountList(.coordinate(.copyAddress(address))):
				return Effect(value: .internal(.system(.copyAddress(address))))

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
				return Effect(value: .internal(.system(.copyAddress(address))))

			case .accountDetails(.coordinate(.displayTransfer)):
				state.transfer = .init()
				return .none

			case let .accountDetails(.coordinate(.refresh(address))):
				return .run { send in
					let accountWorth = try await environment.accountWorthFetcher.fetchWorth([address])
					await send(.internal(.system(.accountWorthLoaded(accountWorth))))
				}

			case .accountDetails(.aggregatedValue(.internal(_))):
				return .none

			case .accountDetails(.aggregatedValue(.coordinate(.toggleIsCurrencyAmountVisible))):
				return Effect(value: .internal(.system(.toggleIsCurrencyAmountVisible)))

			case .accountDetails(.assetList(_)):
				return .none

			case .transfer(.coordinate(.dismissTransfer)):
				state.transfer = nil
				return .none

			case .createAccount(.coordinate(.dismissCreateAccount)):
				state.createAccount = nil
				return .none

			case .transfer(.internal):
				return .none
			}
		}
	)
}
