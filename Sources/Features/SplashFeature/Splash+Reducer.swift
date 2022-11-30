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
			return .run { send in
				let result = await profileLoader.loadProfile()
				await send(.internal(.system(.loadProfileResult(
					result
				))))
			}

		case let .internal(.system(.loadProfileResult(result))):
			return .run { send in
				await delay()
				await send(.delegate(.profileResultLoaded(result)))
			}

		case .delegate:
			return .none
		}
	}

	func delay() async {
		let durationInMS: Int
		#if DEBUG
		durationInMS = 100
		#else
		durationInMS = 700
		#endif
		try? await mainQueue.sleep(for: .milliseconds(durationInMS))
	}
}
