import Common
import ComposableArchitecture
import ErrorQueue
import Foundation
import LocalAuthenticationClient
import ProfileLoader

// MARK: - Splash
public struct Splash: Sendable, ReducerProtocol {
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.localAuthenticationClient) var localAuthenticationClient
	@Dependency(\.profileLoader) var profileLoader

	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.viewAppeared)):
			return .run { send in
				await send(.internal(.system(.loadProfile)))
			}

		case .internal(.view(.alertRetryButtonTapped)):
			return .run { send in
				await send(.internal(.system(.verifyBiometrics)))
			}

		case .internal(.system(.verifyBiometrics)):
			return .run { send in
				await send(.internal(.system(.biometricsConfigResult(
					TaskResult {
						try await localAuthenticationClient.queryConfig()
					}
				))))
			}

		case let .internal(.system(.biometricsConfigResult(result))):
			let config = try? result.value
			guard config?.isBiometricsSetUp == true else {
				state.alert = .init(
					title: .init(L10n.Splash.biometricsNotSetUpTitle),
					message: .init(L10n.Splash.biometricsNotSetUpMessage)
				)
				return .none
			}

			precondition(state.profileResult != nil)

			return .run { [profileResult = state.profileResult] send in
				await send(.delegate(.profileResultLoaded(profileResult!)))
			}

		case .internal(.system(.loadProfile)):
			return .run { send in
				let result = await profileLoader.loadProfile()
				await send(.internal(.system(.loadProfileResult(
					result
				))))
			}

		case let .internal(.system(.loadProfileResult(result))):
			state.profileResult = result
			return .run { send in
				await delay()
				await send(.internal(.system(.verifyBiometrics)))
			}

		case .delegate:
			return .none
		}
	}

	func delay() async {
		let durationInMS: Int
		#if DEBUG
		durationInMS = 200
		#else
		durationInMS = 800
		#endif
		try? await mainQueue.sleep(for: .milliseconds(durationInMS))
	}
}
