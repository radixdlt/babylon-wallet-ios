import ComposableArchitecture
import ErrorQueue
import Foundation
import ProfileLoader

// MARK: - Splash
public struct Splash: Sendable, ReducerProtocol {
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileLoader) var profileLoader

	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.viewAppeared)):
			return .run { send in
				await send(.internal(.system(.loadProfile)))
			}

		case .internal(.system(.loadProfile)):
			return .run { [profileLoader] send in
				await send(.internal(.system(.loadProfileResult(
					TaskResult {
						try await delay()
						return await profileLoader.loadProfile()
					}
				))))
			}

		case let .internal(.system(.loadProfileResult(.success(result)))):
			return .run { send in
				await send(.delegate(.profileResultLoaded(result)))
			}

		// Failed to sleep?
		case let .internal(.system(.loadProfileResult(.failure(error)))):
			errorQueue.schedule(error)
            return .run { send in
				await send(.delegate(.profileResultLoaded(.noProfile)))
			}

		case .delegate:
			return .none
		}
	}

	func delay() async throws {
		let durationInMS: Int
		#if DEBUG
		durationInMS = 100
		#else
		durationInMS = 700
		#endif
		try await mainQueue.sleep(for: .milliseconds(durationInMS))
	}
}
