import Common
import ComposableArchitecture
import Foundation
import HomeFeature
import SettingsFeature
import UIKit
import UserDefaultsClient
import Wallet

public extension Main {
	// MARK: Reducer
	static let reducer = ComposableArchitecture.Reducer<State, Action, Environment>.combine(
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

		Reducer { state, action, environment in
			switch action {
			case .internal(.user(.removeWallet)):
				return Effect(value: .internal(.system(.removedWallet)))

			case .internal(.system(.removedWallet)):
				return .concatenate(
					environment
						.userDefaultsClient
						.removeProfileName()
						.subscribe(on: environment.backgroundQueue)
						.receive(on: environment.mainQueue)
						.fireAndForget(),

					Effect(value: .coordinate(.removedWallet))
				)

			case .coordinate:
				return .none
			case .home(.coordinate(.displaySettings)):
				state.settings = .init()
				return .none
			case .home(.coordinate(.displayVisitHub)):
				return .fireAndForget { UIApplication.shared.open(URL(string: "https://www.apple.com")!) }
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
