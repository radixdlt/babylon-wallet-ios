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
					Home.Environment()
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
			}
		}
	).debug()
}
