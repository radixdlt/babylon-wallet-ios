import Common
import ComposableArchitecture
import ErrorQueue
import Foundation
import LocalAuthenticationClient
import PlatformEnvironmentClient
import ProfileLoader

// MARK: - Splash
public struct Splash: Sendable, ReducerProtocol {
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.localAuthenticationClient) var localAuthenticationClient
	@Dependency(\.platformEnvironmentClient) var platformEnvironmentClient
	@Dependency(\.profileLoader) var profileLoader

	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.viewAppeared)):
			return loadProfile()

		case .internal(.view(.alertRetryButtonTapped)):
			state.alert = nil
			return verifyBiometrics()

		case let .internal(.system(.biometricsConfigResult(result))):
			let config = try? result.value
			guard config?.isBiometricsSetUp == true else {
				state.alert = .init(
					title: .init(L10n.Splash.biometricsNotSetUpTitle),
					message: .init(L10n.Splash.biometricsNotSetUpMessage)
				)
				return .none
			}
			return notifyDelegate(profileResult: state.profileResult)

		case let .internal(.system(.loadProfileResult(result))):
			state.profileResult = result

			if platformEnvironmentClient.isSimulator() {
				return delay().concatenate(with: notifyDelegate(profileResult: state.profileResult))
			} else {
				return delay().concatenate(with: verifyBiometrics())
			}

		case .delegate:
			return .none
		}
	}

	func delay() -> EffectTask<Action> {
		.run { _ in
			let durationInMS: Int
			#if DEBUG
			durationInMS = 200
			#else
			durationInMS = 800
			#endif
			try? await mainQueue.sleep(for: .milliseconds(durationInMS))
		}
	}

	func loadProfile() -> EffectTask<Action> {
		.run { send in
			let result = await profileLoader.loadProfile()
			await send(.internal(.system(.loadProfileResult(
				result
			))))
		}
	}

	func notifyDelegate(profileResult: ProfileLoader.ProfileResult?) -> EffectTask<Action> {
		precondition(profileResult != nil)

		return .run { send in
			await send(.delegate(.profileResultLoaded(profileResult!)))
		}
	}

	func verifyBiometrics() -> EffectTask<Action> {
		.run { send in
			await send(.internal(.system(.biometricsConfigResult(
				TaskResult {
					try await localAuthenticationClient.queryConfig()
				}
			))))
		}
	}
}
