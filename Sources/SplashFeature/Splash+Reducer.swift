import ComposableArchitecture
import Foundation
import ProfileLoader
import WalletLoader

public extension Splash {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, environment in
		switch action {
		case .internal(.system(.viewDidAppear)):
			return .run { send in
				await send(.internal(.system(.loadProfile)))
			}

		case .internal(.system(.loadProfile)):
			return .run { send in
				await send(.internal(.system(.loadProfileResult(
					TaskResult {
						try await environment.profileLoader.loadProfile()
					}
				))))
			}

		case let .internal(.system(.loadProfileResult(.success(.some(profile))))):
			return .run { send in
				await send(.internal(.coordinate(.loadProfileResult(SplashLoadProfileResult.profileLoaded(profile)))))
			}

		case .internal(.system(.loadProfileResult(.success(.none)))):
			return .run { send in
				await send(.internal(.coordinate(.loadProfileResult(SplashLoadProfileResult.noProfile(reason: "No profile saved yet", failedToDecode: false)))))
			}

		case let .internal(.system(.loadProfileResult(.failure(error)))):
			return .run { send in
				await send(.internal(.coordinate(.loadProfileResult(SplashLoadProfileResult.noProfile(reason: String(describing: error), failedToDecode: error is Swift.DecodingError)))))
			}
		case let .internal(.coordinate(actionToCoordinate)):
			return .run { send in
				let durationInMS: Int
				#if DEBUG
				durationInMS = 100
				#else
				durationInMS = 700
				#endif
				try await environment.mainQueue.sleep(for: .milliseconds(durationInMS))
				await send(.coordinate(actionToCoordinate))
			}

		case .coordinate:
			return .none
		}
	}
}
