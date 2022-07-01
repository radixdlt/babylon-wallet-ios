//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import Common
import ComposableArchitecture
import Foundation
import Profile
import UserDefaultsClient
import Wallet

public extension Onboarding {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { state, action, environment in
		switch action {
		case .coordinate:
			return .none
		case .internal(.user(.createWallet)):
			return Effect(value: .internal(.system(.createWallet)))
		case .internal(.system(.createWallet)):
			precondition(state.canProceed)
			let profile = Profile(name: state.profileName)
			let wallet = Wallet(profile: profile)

			return .concatenate(
				environment
					.userDefaultsClient
					.setProfileName(state.profileName)
					.subscribe(on: environment.backgroundQueue)
					.receive(on: environment.mainQueue)
					.fireAndForget(),

				Effect(value: .internal(.system(.createWalletResult(.success(wallet)))))
			)

		case let .internal(.system(.createWalletResult(.success(wallet)))):
			return Effect(value: .coordinate(.onboardedWithWallet(wallet)))
		case .binding:
			state.canProceed = !state.profileName.isEmpty
			return .none
		}
	}
	.binding()
}
