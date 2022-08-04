//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import Common
import ComposableArchitecture
import Foundation
import HomeFeature
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
