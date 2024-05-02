@testable import Radix_Wallet_Dev
import Sargon
import XCTest

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
				Profile.withOneAccount
			}
		}

		// when
		await store.send(.view(.appeared))

		await clock.advance(by: .seconds(0.4))
		await store.receive(.internal(.passcodeConfigResult(.success(authBiometricsConfig)))) {
			$0.biometricsCheckFailed = true
			$0.destination = .passcodeCheckFailed(.init(
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
			))
		}
	}
}
