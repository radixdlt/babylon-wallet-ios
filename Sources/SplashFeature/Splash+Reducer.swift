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
				await send(.internal(.system(.loadProfileResult(
					TaskResult {
						try await environment.profileLoader.loadProfile()
					}
				))))
			}

		case let .internal(.system(.loadProfileResult(.success(profile)))):
			return Effect(value: .internal(.system(.loadWalletWithProfile(profile))))

		case let .internal(.system(.loadProfileResult(.failure(error)))):
			return .run { send in
				switch error {
				case ProfileLoader.Error.failedToDecode:
					await send(.internal(.coordinate(.loadWalletResult(
						.noWallet(
							reason: "Failed to load profile",
							failedToDecode: true
						)
					))))
				default:
					await send(.internal(.coordinate(.loadWalletResult(
						.noWallet(
							reason: "Failed to load profile",
							failedToDecode: false
						)
					))))
				}
			}

		case let .internal(.system(.loadWalletWithProfile(profile))):
			return .run { send in
				await send(.internal(.system(.loadWalletWithProfileResult(
					TaskResult {
						try await environment.walletLoader.loadWallet(profile)
					}, profile: profile
				)
				)))
			}

		case let .internal(.system(.loadWalletWithProfileResult(.success(wallet), _))):
			return Effect(value: .internal(.coordinate(.loadWalletResult(.walletLoaded(wallet)))))

		case let .internal(.system(.loadWalletWithProfileResult(.failure(error), _))):
			switch error {
			case WalletLoader.Error.secretsNoFoundForProfile:
				return Effect(value: .internal(.coordinate(.loadWalletResult(.noWallet(reason: "Failed to load profile", failedToDecode: false)))))
			default:
				return Effect(value: .internal(.coordinate(.loadWalletResult(.noWallet(reason: "Failed to decode wallet", failedToDecode: true)))))
			}

		case let .internal(.coordinate(actionToCoordinate)):
			return .run { send in
				let duration: TimeInterval
				#if DEBUG
				duration = 0.1
				#else
				duration = 0.7
				#endif
				try await Task.sleep(nanoseconds: UInt64(duration * TimeInterval(NSEC_PER_SEC)))
				await send(.coordinate(actionToCoordinate))
			}

		case .coordinate:
			return .none
		}
	}
}
