import ComposableArchitecture
import Foundation
import ProfileLoader

public struct Splash: ReducerProtocol {
	public init() {}

	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.profileLoader) var profileLoader

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.system(.viewDidAppear)):
			return .run { send in
				await send(.internal(.system(.loadProfile)))
			}

		case .internal(.system(.loadProfile)):
			return .run { [profileLoader] send in
				await send(.internal(.system(.loadProfileResult(
					TaskResult {
						try await profileLoader.loadProfile()
					}
				))))
			}

		case let .internal(.system(.loadProfileResult(.success(.some(profile))))):
			return .run { send in
				await send(
					.internal(
						.coordinate(
							.loadProfileResult(
								.profileLoaded(profile)
							)
						)
					)
				)
			}

		case .internal(.system(.loadProfileResult(.success(.none)))):
			return .run { send in
				await send(
					.internal(
						.coordinate(
							.loadProfileResult(
								.noProfile(
									reason: "No profile saved yet",
									failedToDecode: false
								)
							)
						)
					)
				)
			}

		case let .internal(.system(.loadProfileResult(.failure(error)))):
			return .run { send in
				await send(
					.internal(
						.coordinate(
							.loadProfileResult(
								.noProfile(
									reason: String(describing: error),
									failedToDecode: error is Swift.DecodingError
								)
							)
						)
					)
				)
			}
		case let .internal(.coordinate(actionToCoordinate)):
			return .run { [mainQueue] send in
				let durationInMS: Int
				#if DEBUG
				durationInMS = 100
				#else
				durationInMS = 700
				#endif
				try await mainQueue.sleep(for: .milliseconds(durationInMS))
				await send(.delegate(actionToCoordinate))
			}

		case .delegate:
			return .none
		}
	}
}
