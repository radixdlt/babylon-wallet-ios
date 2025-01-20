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
			initialState: Splash.State(context: .appForegrounded),
			reducer: Splash.init
		) {
			$0.localAuthenticationClient = LocalAuthenticationClient(
				queryConfig: { authBiometricsConfig },
				authenticateWithBiometrics: { true },
				setAuthenticatedSuccessfully: unimplemented("\(Self.self).setAuthenticatedSuccessfully"),
				authenticatedSuccessfully: unimplemented("\(Self.self).authenticatedSuccessfully")
			)

			$0.continuousClock = clock
			$0.onboardingClient.loadProfileState = {
				var profile = Profile.withOneAccount
				profile.appPreferences.security.isAdvancedLockEnabled = true
				return .loaded(profile)
			}
			$0.userDefaults = userDefaults
			$0.secureStorageClient.saveDeviceInfo = { _ in }
			$0.secureStorageClient.loadDeviceInfo = { nil }
		}

		// when
		await store.send(.view(.appeared))

		await clock.advance(by: .seconds(0.4))
		if #available(iOS 18, *) {
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
		} else {
			await store.receive(.internal(.advancedLockStateLoaded(isEnabled: true)))
			await store.receive(.internal(.passcodeConfigResult(.success(authBiometricsConfig)))) {
				$0.biometricsCheckFailed = true
				$0.destination = .errorAlert(.init(
					title: { .init(L10n.Splash.PasscodeCheckFailedAlert.title) },
					actions: {
						ButtonState(
							role: .none,
							action: .send(.retryVerifyPasscodeButtonTapped),
							label: { TextState(L10n.Common.retry) }
						)
						ButtonState(
							role: .none,
							action: .send(.openSettingsButtonTapped),
							label: { TextState(L10n.Common.systemSettings) }
						)
					},
					message: { .init(L10n.Splash.PasscodeCheckFailedAlert.message) }
				))
			}
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
		) { [profile] in
			$0.localAuthenticationClient = LocalAuthenticationClient(
				queryConfig: { authBiometricsConfig },
				authenticateWithBiometrics: { true },
				setAuthenticatedSuccessfully: unimplemented("\(Self.self).setAuthenticatedSuccessfully"),
				authenticatedSuccessfully: unimplemented("\(Self.self).authenticatedSuccessfully")
			)

			$0.continuousClock = clock
			$0.onboardingClient.loadProfileState = {
				.loaded(profile)
			}
			$0.secureStorageClient.loadProfileSnapshotData = { _ in
				profile.jsonData()
			}
			$0.secureStorageClient = .previewValue
		}

		// when
		await store.send(.view(.appeared))

		await clock.advance(by: .seconds(0.4))
		await store.receive(.internal(.advancedLockStateLoaded(isEnabled: false)))
		await store.receive(.delegate(.completed(.loaded(profile))))
	}
}
