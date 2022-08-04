import Common
import ComposableArchitecture
import Foundation
import Profile
import ProfileLoader
import Wallet
import WalletLoader

public extension Splash {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, environment in
		switch action {
		case .internal(.system(.viewDidAppear)):
			return Effect(value: .internal(.system(.loadProfile)))
		case .internal(.system(.loadProfile)):
			return environment
				.profileLoader
				.loadProfile()
				.subscribe(on: environment.backgroundQueue)
				.receive(on: environment.mainQueue)
				.catchToEffect { Splash.Action.internal(.system(.loadProfileResult($0))) }

		case let .internal(.system(.loadProfileResult(.success(profile)))):
			return Effect(value: .internal(.system(.loadWalletWithProfile(profile))))
		case let .internal(.system(.loadProfileResult(.failure(.noProfileDocumentFoundAtPath(path))))):
			return Effect(value: .internal(.coordinate(.loadWalletResult(.noWallet(reason: .noProfileFoundAtPath(path))))))
		case .internal(.system(.loadProfileResult(.failure(.failedToLoadProfileFromDocument)))):
			return Effect(value: .internal(.coordinate(.loadWalletResult(.noWallet(reason: .failedToLoadProfileFromDocument)))))

		case let .internal(.system(.loadWalletWithProfile(profile))):
			return environment
				.walletLoader
				.loadWallet(profile)
				.subscribe(on: environment.backgroundQueue)
				.receive(on: environment.mainQueue)
				.catchToEffect { Splash.Action.internal(.system(.loadWalletWithProfileResult($0, profile: profile))) }

		case let .internal(.system(.loadWalletWithProfileResult(.success(wallet), _))):
			return Effect(value: .internal(.coordinate(.loadWalletResult(.walletLoaded(wallet)))))
		case let .internal(.system(.loadWalletWithProfileResult(.failure(.secretsNoFoundForProfile), profile))):
			return Effect(value: .internal(.coordinate(.loadWalletResult(.noWallet(reason: .secretsNotFoundForProfile(profile))))))
		case let .internal(.coordinate(actionToCoordinate)):
			return Effect(value: .coordinate(actionToCoordinate))
				.delay(for: 0.7, scheduler: environment.mainQueue)
				.eraseToEffect()
		case .coordinate:
			return .none
		}
	}
}
