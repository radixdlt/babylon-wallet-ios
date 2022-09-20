import ComposableArchitecture
import ProfileLoader
import WalletLoader

public extension Splash {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, environment in
		switch action {
		case .internal(.system(.viewDidAppear)):
			return Effect(value: .internal(.system(.loadProfile)))
		case .internal(.system(.loadProfile)):
			return .run { send in
				let profile = try await environment.profileLoader.loadProfile()
				await send(.internal(.system(.loadProfileResult(.success(profile)))))
			}

		case let .internal(.system(.loadProfileResult(.success(profile)))):
			return Effect(value: .internal(.system(.loadWalletWithProfile(profile))))

		case let .internal(.system(.loadProfileResult(.failure(error)))):
			return .run { send in
				switch error {
				case ProfileLoader.Error.noProfileDocumentFoundAtPath:
					break
				case ProfileLoader.Error.failedToLoadProfileFromDocument:
					await send(.internal(.coordinate(.loadWalletResult(.noWallet(reason: "Failed to load profile")))))
				default:
					break
				}
			}

		case let .internal(.system(.loadWalletWithProfile(profile))):
			return .run { send in
				let wallet = try await environment.walletLoader.loadWallet(profile)
				await send(.internal(.system(.loadWalletWithProfileResult(.success(wallet), profile: profile))))
			}

		case let .internal(.system(.loadWalletWithProfileResult(.success(wallet), _))):
			return Effect(value: .internal(.coordinate(.loadWalletResult(.walletLoaded(wallet)))))

		case let .internal(.system(.loadWalletWithProfileResult(.failure(error), _))):
			switch error {
			case WalletLoader.Error.secretsNoFoundForProfile:
				return Effect(value: .internal(.coordinate(.loadWalletResult(.noWallet(reason: "Failed to load profile")))))
			default:
				return .none
			}

		case let .internal(.coordinate(actionToCoordinate)):
			return Effect(value: .coordinate(actionToCoordinate))
				.delay(for: 0.7, scheduler: environment.mainQueue)
				.eraseToEffect()
		case .coordinate:
			return .none
		}
	}
}
