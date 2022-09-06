import AccountWorthFetcher
import ComposableArchitecture

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

		Home.AggregatedValue.reducer
			.pullback(
				state: \.aggregatedValue,
				action: /Home.Action.aggregatedValue,
				environment: { _ in Home.AggregatedValue.Environment() }
			),

		Home.VisitHub.reducer
			.pullback(
				state: \.visitHub,
				action: /Home.Action.visitHub,
				environment: { _ in Home.VisitHub.Environment() }
			),

		Home.AccountList.reducer
			.pullback(
				state: \.accountList,
				action: /Home.Action.accountList,
				environment: { _ in Home.AccountList.Environment() }
			),

		Home.AccountDetails.reducer
			.optional()
			.pullback(
				state: \.accountDetails,
				action: /Home.Action.accountDetails,
				environment: { _ in
					Home.AccountDetails.Environment()
				}
			),

		Home.AccountPreferences.reducer
			.optional()
			.pullback(
				state: \.accountPreferences,
				action: /Home.Action.accountPreferences,
				environment: { _ in
					Home.AccountPreferences.Environment()
				}
			),

		Home.Transfer.reducer
			.optional()
			.pullback(
				state: \.transfer,
				action: /Home.Action.transfer,
				environment: { _ in
					Home.Transfer.Environment()
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
					let currency = try await environment.appSettingsClient.loadCurrency()
					await send(.internal(.system(.currencyLoaded(currency))))
					let isVisible = try await environment.appSettingsClient.loadIsCurrencyAmountVisible()
					await send(.internal(.system(.isCurrencyAmountVisibleLoaded(isVisible))))
				}

			case let .internal(.system(.currencyLoaded(currency))):
				state.aggregatedValue.currency = currency
				state.accountList.accounts.forEach {
					state.accountList.accounts[id: $0.address]?.currency = currency
				}
				return .none

			case .internal(.system(.toggleIsCurrencyAmountVisible)):
				return .run { send in
					var isVisible = try await environment.appSettingsClient.loadIsCurrencyAmountVisible()
					isVisible.toggle()
					try await environment.appSettingsClient.saveIsCurrencyAmountVisible(isVisible)
					await send(.internal(.system(.isCurrencyAmountVisibleLoaded(isVisible))))
				}

			case let .internal(.system(.isCurrencyAmountVisibleLoaded(isVisible))):
				state.aggregatedValue.isCurrencyAmountVisible = isVisible
				state.accountList.accounts.forEach {
					state.accountList.accounts[id: $0.address]?.isCurrencyAmountVisible = isVisible
				}
				state.accountDetails?.aggregatedValue.isCurrencyAmountVisible = isVisible
				return .none

			case let .internal(.system(.totalWorthLoaded(totalWorth))):
				state.accountsWorthDictionary = totalWorth
				state.aggregatedValue.value = totalWorth.compactMap(\.value.worth).reduce(0, +)
				state.accountList.accounts.forEach {
					state.accountList.accounts[id: $0.address]?.aggregatedValue = totalWorth[$0.address]?.worth

					let tokens = totalWorth[$0.address]?.tokenContainers.map(\.token) ?? []
					state.accountList.accounts[id: $0.address]?.tokens = tokens
				}
				return .none

            case let .internal(.system(.copyAddress(address))):
                // TODO: display confirmation popup? discuss with po / designer
                return .run { _ in
                    environment.pasteboardClient.copyString(address)
                }
                
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

			case .accountDetails(.aggregatedValue(.internal(_))):
				return .none

			case .accountDetails(.aggregatedValue(.coordinate(.toggleIsCurrencyAmountVisible))):
				return Effect(value: .internal(.system(.toggleIsCurrencyAmountVisible)))

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
