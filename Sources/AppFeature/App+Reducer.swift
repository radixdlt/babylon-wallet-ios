//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import ComposableArchitecture
import MainFeature
import OnboardingFeature
import ProfileLoader
import SplashFeature
import UserDefaultsClient
import Wallet
import WalletLoader

public extension App {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>

	static let reducer = Reducer.combine(
		Main.reducer
			.optional()
			.pullback(
				state: \.main,
				action: /Action.main,
				environment: {
					Main.Environment(
						backgroundQueue: $0.backgroundQueue,
						mainQueue: $0.mainQueue,
						userDefaultsClient: $0.userDefaultsClient
					)
				}
			),

		Onboarding.reducer
			.optional()
			.pullback(
				state: \.onboarding,
				action: /Action.onboarding,
				environment: {
					Onboarding.Environment(
						backgroundQueue: $0.backgroundQueue,
						mainQueue: $0.mainQueue,
						userDefaultsClient: $0.userDefaultsClient
					)
				}
			),

		Splash.reducer
			.optional()
			.pullback(
				state: \.splash,
				action: /Action.splash,
				environment: {
					Splash.Environment(
						backgroundQueue: $0.backgroundQueue,
						mainQueue: $0.mainQueue,
						profileLoader: $0.profileLoader,
						walletLoader: $0.walletLoader
					)
				}
			),

		appReducer
	)
	.debug()

	static let appReducer = Reducer { state, action, _ in
		switch action {
		case .main(.coordinate(.removedWallet)):
			state.main = nil
			return Effect(value: .coordinate(.onboard))
		case .home:
			return .none
		case .main:
			return .none
		case let .onboarding(.coordinate(.onboardedWithWallet(wallet))):
			state.onboarding = nil
			return Effect(value: .coordinate(.toMain(wallet)))
		case .onboarding:
			return .none

		case let .splash(.coordinate(.loadWalletResult(loadWalletResult))):

			state.splash = nil
			switch loadWalletResult {
			case let .walletLoaded(wallet):
				return Effect(value: .coordinate(.toMain(wallet)))
			case let .noWallet(.noProfileFoundAtPath(path)):
				state.alert = .init(
					title: TextState("No profile found at: \(path)"),
					buttons: [
						.cancel(
							TextState("OK, I'll onboard"),
							action: .send(.coordinate(.onboard))
						),
					]
				)
				return .none
			case .noWallet(.failedToLoadProfileFromDocument):
				state.alert = .init(
					title: TextState("Failed to load profile from document"),
					buttons: [
						.cancel(
							TextState("OK, I'll onboard"),
							action: .send(.coordinate(.onboard))
						),
					]
				)
				return .none
			case .noWallet(.secretsNotFoundForProfile):
				state.alert = .init(
					title: TextState("Secrets not found for profile"),
					buttons: [
						.cancel(
							TextState("OK, I'll onboard"),
							action: .send(.coordinate(.onboard))
						),
					]
				)
				return .none
			}

		case .splash:
			return .none

		case .coordinate(.onboard):
			state.onboarding = .init()
			return .none
		case let .coordinate(.toMain(wallet)):
			state.main = .init(wallet: wallet)
			return .none
		case .internal(.user(.alertDismissed)):
			state.alert = nil
			return .none
		}
	}
}
