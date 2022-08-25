import Common
import ComposableArchitecture
import CreateAccount
import Foundation
import HomeFeature
import SettingsFeature
import UserDefaultsClient
import Wallet

#if os(iOS)
// FIXME: move to `UIApplicationClient` package!
import UIKit
#endif

public extension Main {
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>

	// MARK: Reducer
	static let reducer = Reducer.combine(
		Home.reducer
			.pullback(
				state: \.home,
				action: /Main.Action.home,
				environment: { _ in
					// FIXME: remove placeholder with real implementation
					Home.Environment(wallet: .placeholder)
				}
			),

		Settings.reducer
			.optional()
			.pullback(
				state: \.settings,
				action: /Main.Action.settings,
				environment: { _ in
					Settings.Environment()
				}
			),

		CreateAccount.reducer
			.optional()
			.pullback(
				state: \.createAccount,
				action: /Main.Action.createAccount,
				environment: { _ in
					CreateAccount.Environment()
				}
			),

		Home.AccountDetails.reducer
			.optional()
			.pullback(
				state: \.account,
				action: /Main.Action.accountDetails,
				environment: { _ in
					Home.AccountDetails.Environment()
				}
			),

		Home.AccountPreferences.reducer
			.optional()
			.pullback(
				state: \.accountPreferences,
				action: /Main.Action.accountPreferences,
				environment: { _ in
					Home.AccountPreferences.Environment()
				}
			),

		Reducer { state, action, environment in
			switch action {
			case .internal(.user(.removeWallet)):
				return Effect(value: .internal(.system(.removedWallet)))

			case .internal(.system(.removedWallet)):
				return .run { send in
					await environment.userDefaultsClient.removeProfileName()
					await send(.coordinate(.removedWallet))
				}

			case .home(.coordinate(.displaySettings)):
				state.settings = .init()
				return .none
			case .home(.coordinate(.displayVisitHub)):
				#if os(iOS)
				// FIXME: move to `UIApplicationClient` package!
				return .fireAndForget {
					UIApplication.shared.open(URL(string: "https://www.apple.com")!)
				}
				#else
				return .none
				#endif // os(iOS)
			case .home(.coordinate(.displayCreateAccount)):
				state.createAccount = .init()
				return .none

			case .settings(.coordinate(.dismissSettings)):
				state.settings = nil
				return .none

			case .createAccount(.coordinate(.dismissCreateAccount)):
				state.createAccount = nil
				return .none

			case let .home(.coordinate(.displayAccountDetails(account))):
				state.account = .init(for: account)
				return .none

			case let .home(.coordinate(.copyAddress(account))):
				return .run { _ in
					environment.pasteboardClient.copyString(account.address)
				}

			case .home(.internal(_)):
				return .none
			case .settings(.internal(_)):
				return .none
			case .home(.header(_)):
				return .none
			case .home(.accountList(_)):
				return .none
			case .home(.aggregatedValue(_)):
				return .none
			case .home(.visitHub(_)):
				return .none
			case .coordinate:
				return .none
			case .accountDetails(.coordinate(.dismissAccountDetails)):
				state.account = nil
				return .none
			case .accountDetails(.internal(_)):
				return .none
			case .accountDetails(.aggregatedValue(_)):
				return .none
			case .accountDetails(.coordinate(.displayAccountPreferences)):
				state.accountPreferences = .init()
				return .none
			case .accountPreferences:
				return .none
			}
		}
	).debug()
}
