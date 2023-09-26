import FeatureTestingPrelude
import LocalAuthenticationClient
import OnboardingClient
@testable import SplashFeature

// MARK: - SplashFeatureTests
@MainActor
final class SplashFeatureTests: TestCase {
	func test__GIVEN__splash_appeared__WHEN__no_biometrics_config__THEN__alert_is_shown() async throws {
		let authBiometricsConfig = LocalAuthenticationConfig.neitherBiometricsNorPasscodeSetUp

		let clock = TestClock()

		let store = TestStore(
			initialState: Splash.State(),
			reducer: Splash.init
		) {
			$0.localAuthenticationClient = LocalAuthenticationClient {
				authBiometricsConfig
			}

			$0.continuousClock = clock
			$0.onboardingClient.loadProfile = {
				.newUser
			}
		}

		// when
		await store.send(.view(.appeared))

		await clock.advance(by: .seconds(0.4))
		await store.receive(.internal(.passcodeConfigResult(.success(authBiometricsConfig)))) {
			$0.passcodeCheckFailedAlert = .init(
				title: { .init(L10n.Splash.PasscodeCheckFailedAlert.title) },
				actions: {
					ButtonState(
						role: .none,
						action: .send(.retryButtonTapped),
						label: { TextState(L10n.Common.retry) }
					)
					ButtonState(
						role: .none,
						action: .send(.openSettingsButtonTapped),
						label: { TextState(L10n.Common.systemSettings) }
					)
				},
				message: { .init(L10n.Splash.PasscodeCheckFailedAlert.message) }
			)
		}
	}

	func test__GIVEN__splash_appeared__WHEN__biometrics_configured__THEN__notifies_delegate_with_profile_result() async throws {
		try await assertNotifiesDelegateWithLoadProfileOutcome(.newUser)
		try await assertNotifiesDelegateWithLoadProfileOutcome(.existingProfile)

		/// Profile load failure
		try await assertNotifiesDelegateWithLoadProfileOutcome(
			.usersExistingProfileCouldNotBeLoaded(failure: .profileVersionOutdated(json: Data(), version: .minimum))
		)
		try await assertNotifiesDelegateWithLoadProfileOutcome(
			.usersExistingProfileCouldNotBeLoaded(failure: .failedToCreateProfileFromSnapshot(.init(version: .minimum, error: NSError.any))
			))

		try await assertNotifiesDelegateWithLoadProfileOutcome(
			.usersExistingProfileCouldNotBeLoaded(failure: .decodingFailure(json: Data(), .unknown(.init(error: NSError.any))))
		)
	}

	func assertNotifiesDelegateWithLoadProfileOutcome(_ outcome: LoadProfileOutcome) async throws {
		let authBiometricsConfig = LocalAuthenticationConfig.biometricsAndPasscodeSetUp
		let clock = TestClock()
		let store = TestStore(
			initialState: Splash.State(),
			reducer: Splash.init
		) {
			$0.localAuthenticationClient = LocalAuthenticationClient {
				authBiometricsConfig
			}
			$0.continuousClock = clock
			$0.onboardingClient.loadProfile = {
				outcome
			}
			$0.deviceFactorSourceClient.isAccountRecoveryNeeded = {
				false
			}
			$0.networkSwitchingClient.hasMainnetEverBeenLive = { false }
		}

		// when
		await store.send(.view(.appeared))

		// then
		await clock.advance(by: .seconds(0.4))
		await store.receive(.internal(.passcodeConfigResult(.success(authBiometricsConfig))))
		await store.receive(.internal(.loadProfileOutcome(outcome)))
		if case .existingProfile = outcome {
			await store.receive(.internal(.accountRecoveryNeeded(outcome, .success(false))))
		}
		await store.receive(.delegate(.completed(outcome, accountRecoveryNeeded: false, hasMainnetEverBeenLive: false)))
	}
}

extension NSError {
	static var any: NSError {
		NSError(domain: "Test", code: -1000)
	}
}
