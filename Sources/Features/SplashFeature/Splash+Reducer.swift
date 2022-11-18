import ComposableArchitecture
import ErrorQueue
import Foundation
import ProfileLoader

// MARK: - Splash
public struct Splash: ReducerProtocol {
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
						try await profileLoader.loadProfile()
					}
				))))
			}

		case let .internal(.system(.loadProfileResult(loadResult))):
			return .run { send in
				try await delay()

				switch loadResult {
				case let .success(profile?):
					await send(.delegate(.profileLoaded(profile)))
				case .success(.none):
					errorQueue.schedule(NoProfileError())
					await send(.delegate(.profileLoaded(nil)))
				case let .failure(error as Swift.DecodingError):
					errorQueue.schedule(FailedToDecodeProfileError(error: error))
				case let .failure(error):
					errorQueue.schedule(error)
				}
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

public extension Splash {
	struct FailedToDecodeProfileError: LocalizedError {
		let error: DecodingError
		public var errorDescription: String? { "Failed to decode profile: \(String(describing: error))" }
	}

	struct NoProfileError: LocalizedError {
		public let errorDescription: String? = "No profile saved yet"
	}
}
