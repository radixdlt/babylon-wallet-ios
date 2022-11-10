import ComposableArchitecture
import Foundation
import ProfileLoader

public struct Splash: ReducerProtocol {
	public init() {}

	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.profileLoader) var profileLoader

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
				let result: SplashLoadProfileResult = {
					switch loadResult {
					case let .success(profile?):
						return .profileLoaded(profile)
					case .success(.none):
						return .noProfile(reason: "No profile saved yet", failedToDecode: false)
					case let .failure(error):
						return .noProfile(reason: String(describing: error), failedToDecode: error is Swift.DecodingError)
					}
				}()

				try await delay()
				await send(.delegate(.loadProfileResult(result)))
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
