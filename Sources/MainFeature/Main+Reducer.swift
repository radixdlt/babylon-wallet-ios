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
	//    typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = ComposableArchitecture.Reducer<State, Action, Environment>.combine(
		Home.reducer
			.optional()
			.pullback(
				state: \.home,
				action: /Main.Action.home,
				environment: { _ in
					Home.Environment()
				}
			),

		Reducer { _, action, environment in
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
//            case .home(.coordinate(.displaySettings)):
//                break
			case .home:
				return .none
			}
		}
	)
}
