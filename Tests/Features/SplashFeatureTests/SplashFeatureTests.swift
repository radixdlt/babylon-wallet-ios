import ComposableArchitecture
import Foundation
import LocalAuthenticationClient
import Profile
import ProfileLoader
@testable import SplashFeature
import TestUtils

@MainActor
final class SplashFeatureTests: TestCase {
	func test__GIVEN__splash_appeared__WHEN__no_biometrics_config__THEN__alert_is_shown() async throws {
		let authBiometricsConfig = LocalAuthenticationConfig.neitherBiometricsNorPasscodeSetUp

		let testScheduler = DispatchQueue.test
		let store = TestStore(
			initialState: Splash.State(),
			reducer: Splash()
		)

		store.dependencies.localAuthenticationClient = LocalAuthenticationClient {
			authBiometricsConfig
		}

		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()

		let newProfile = try await Profile.new(networkAndGateway: .hammunet, mnemonic: .generate())
		store.dependencies.profileLoader = ProfileLoader(loadProfile: {
			.success(newProfile)
		})

		// when
		await store.send(.internal(.view(.viewAppeared)))

		// then
		await store.receive(.internal(.system(.loadProfile)))
		await store.receive(.internal(.system(.loadProfileResult(.success(newProfile))))) {
			$0.profileResult = .success(newProfile)
		}
		await testScheduler.advance(by: .seconds(0.2))
		await store.receive(.internal(.system(.verifyBiometrics)))
		await store.receive(.internal(.system(.biometricsConfigResult(.success(authBiometricsConfig))))) {
			$0.alert = .init(
				title: .init("Biometrics not set up"),
				message: .init("This app requires your phone to have biometrics set up")
			)
		}
	}

	func test__GIVEN__splash_appeared__WHEN__biometrics_configured__THEN__loads_profile() async throws {
		let authBiometricsConfig = LocalAuthenticationConfig.biometricsAndPasscodeSetUp

		let testScheduler = DispatchQueue.test
		let store = TestStore(
			initialState: Splash.State(),
			reducer: Splash()
		)

		store.dependencies.localAuthenticationClient = LocalAuthenticationClient {
			authBiometricsConfig
		}

		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()

		let newProfile = try await Profile.new(networkAndGateway: .hammunet, mnemonic: .generate())
		store.dependencies.profileLoader = ProfileLoader(loadProfile: {
			.success(newProfile)
		})

		// when
		await store.send(.internal(.view(.viewAppeared)))

		// then
		await store.receive(.internal(.system(.loadProfile)))
		await store.receive(.internal(.system(.loadProfileResult(.success(newProfile))))) {
			$0.profileResult = .success(newProfile)
		}
		await testScheduler.advance(by: .seconds(0.2))
		await store.receive(.internal(.system(.verifyBiometrics)))
		await store.receive(.internal(.system(.biometricsConfigResult(.success(authBiometricsConfig)))))
		await store.receive(.delegate(.profileResultLoaded(.success(newProfile))))
	}
}
