import FeatureTestingPrelude
import LocalAuthenticationClient
import OnboardingClient
@testable import SplashFeature

// MARK: - SplashFeatureTests
@MainActor
final class SplashFeatureTests: TestCase {
	func test__GIVEN__splash_appeared__WHEN__no_biometrics_config__THEN__alert_is_shown() async throws {
		let authBiometricsConfig = LocalAuthenticationConfig.neitherBiometricsNorPasscodeSetUp

		let testScheduler = DispatchQueue.test

		let store = TestStore(
			initialState: Splash.State(),
			reducer: Splash()
		) {
			$0.localAuthenticationClient = LocalAuthenticationClient {
				authBiometricsConfig
			}

			$0.mainQueue = testScheduler.eraseToAnyScheduler()
			$0.onboardingClient.loadProfile = {
				.newUser
			}
		}

		let factorSource = try FactorSource.babylon(mnemonic: .generate())

		// when
		await store.send(.view(.appeared))

		// then
		await store.receive(.internal(.loadProfileOutcome(.newUser))) {
			$0.loadProfileOutcome = .newUser
		}
		await testScheduler.advance(by: .seconds(0.2))
		await store.receive(.internal(.biometricsConfigResult(.success(authBiometricsConfig)))) {
			$0.biometricsCheckFailedAlert = .init(
				title: { .init(L10n.Splash.Alert.BiometricsCheckFailed.title) },
				actions: {
					ButtonState(
						role: .cancel,
						action: .send(.cancelButtonTapped),
						label: { TextState(L10n.Splash.Alert.BiometricsCheckFailed.cancelButtonTitle) }
					)
					ButtonState(
						role: .none,
						action: .send(.openSettingsButtonTapped),
						label: { TextState(L10n.Splash.Alert.BiometricsCheckFailed.settingsButtonTitle) }
					)
				},
				message: { .init(L10n.Splash.Alert.BiometricsCheckFailed.message) }
			)
		}
	}

	func test__GIVEN__splash_appeared__WHEN__biometrics_configured__THEN__notifies_delegate_with_profile_result() async throws {
		/// Profile load success
		let factorSource = try FactorSource.babylon(mnemonic: .generate())
		let newProfile = withDependencies { $0.uuid = .incrementing } operation: { Profile(factorSource: factorSource) }
		try await assertNotifiesDelegateWithLoadProfileOutcome(.newUser)
		try await assertNotifiesDelegateWithLoadProfileOutcome(.existingProfileLoaded)

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
		let testScheduler = DispatchQueue.test
		let store = TestStore(
			initialState: Splash.State(),
			reducer: Splash()
		) {
			$0.localAuthenticationClient = LocalAuthenticationClient {
				authBiometricsConfig
			}
			$0.mainQueue = testScheduler.eraseToAnyScheduler()
			$0.onboardingClient.loadProfile = {
				outcome
			}
		}

		// when
		await store.send(.view(.appeared))

		// then
		await store.receive(.internal(.loadProfileOutcome(outcome))) {
			$0.loadProfileOutcome = outcome
		}
		await testScheduler.advance(by: .seconds(0.2))
		await store.receive(.internal(.biometricsConfigResult(.success(authBiometricsConfig))))
		await store.receive(.delegate(.loadProfileOutcome(outcome)))
	}
}

extension NSError {
	static var any: NSError {
		NSError(domain: "Test", code: -1000)
	}
}
