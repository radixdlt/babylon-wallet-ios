@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - SplashFeatureTests
@MainActor
final class SplashFeatureTests: TestCase {
	func test__GIVEN__splash_appeared__WHEN__advanced_lock_enabled__AND__message_not_shown() async throws {
		let authBiometricsConfig = LocalAuthenticationConfig.neitherBiometricsNorPasscodeSetUp

		let clock = TestClock()
		let userDefaults = UserDefaults.Dependency.ephemeral()
		userDefaults.setAppLockMessageShown(false)

		let store = TestStore(
			initialState: Splash.State(),
			reducer: Splash.init
		) {
			$0.localAuthenticationClient = LocalAuthenticationClient(
				queryConfig: { authBiometricsConfig },
				authenticateWithBiometrics: { true },
				setAuthenticatedSuccessfully: unimplemented("\(Self.self).setAuthenticatedSuccessfully"),
				authenticatedSuccessfully: unimplemented("\(Self.self).authenticatedSuccessfully")
			)

			$0.continuousClock = clock
			$0.onboardingClient.loadProfile = {
				var profile = Profile.withOneAccount
				profile.appPreferences.security.isAdvancedLockEnabled = true
				return profile
			}
			$0.userDefaults = userDefaults
		}

		// when
		await store.send(.view(.appeared))

		await clock.advance(by: .seconds(0.4))
		await store.receive(.internal(.showAppLockMessage)) {
			$0.destination = .errorAlert(.init(
				title: { .init(L10n.Biometrics.AppLockAvailableAlert.title) },
				actions: {
					.default(
						.init(L10n.Common.dismiss),
						action: .send(.appLockOkButtonTapped)
					)
				},
				message: { .init(L10n.Biometrics.AppLockAvailableAlert.message) }
			))
		}
	}

	func test__GIVEN__splash_appeared__WHEN__advanced_lock_disabled() async throws {
		let authBiometricsConfig = LocalAuthenticationConfig.neitherBiometricsNorPasscodeSetUp

		let clock = TestClock()

		var profile = Profile.withOneAccount
		profile.appPreferences.security.isAdvancedLockEnabled = false

		let store = TestStore(
			initialState: Splash.State(),
			reducer: Splash.init
		) {
			$0.localAuthenticationClient = LocalAuthenticationClient(
				queryConfig: { authBiometricsConfig },
				authenticateWithBiometrics: { true },
				setAuthenticatedSuccessfully: unimplemented("\(Self.self).setAuthenticatedSuccessfully"),
				authenticatedSuccessfully: unimplemented("\(Self.self).authenticatedSuccessfully")
			)

			$0.continuousClock = clock
			$0.onboardingClient.loadProfile = {
				profile
			}
		}

		// when
		await store.send(.view(.appeared))

		await clock.advance(by: .seconds(0.4))
		await store.receive(.internal(.advancedLockStateLoaded(isEnabled: false)))
		await store.receive(.delegate(.completed(profile)))
	}
}
