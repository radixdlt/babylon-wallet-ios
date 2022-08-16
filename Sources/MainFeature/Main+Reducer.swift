import Common
import ComposableArchitecture
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
	// MARK: Reducer
	static let reducer = ComposableArchitecture.Reducer<State, Action, Environment>.combine(
		Home.reducer
			.pullback(
				state: \.home,
				action: /Main.Action.home,
				environment: {
					.init(
						backgroundQueue: $0.backgroundQueue,
						mainQueue: $0.mainQueue
					)
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

		Reducer { state, action, environment in
			switch action {
			case .internal(.user(.removeWallet)):
				return Effect(value: .internal(.system(.removedWallet)))

			case .internal(.system(.removedWallet)):
				return .run { send in
					await environment.userDefaultsClient.removeProfileName()
					await send(.coordinate(.removedWallet))
				}

			case .coordinate:
				return .none
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
			case .home:
				return .none
			case .settings(.coordinate(.dismissSettings)):
				state.settings = nil
				return .none
			case .settings:
				return .none
			}
		}
	)
}
