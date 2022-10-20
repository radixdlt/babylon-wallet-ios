import ComposableArchitecture
import KeychainClient
import Mnemonic
@testable import OnboardingFeature
import Profile
import TestUtils
import UserDefaultsClient

@MainActor
final class OnboardingFeatureTests: TestCase {
	func test_createWallet_whenTappedOnCreateWalletButton_thenCreateWallet() async throws {
		// given
		var keychainClient: KeychainClient = .unimplemented
		let expectSetDataForProfile = expectation(description: "SetDataForKey on keychainClient should be called for profile snapshot")
		keychainClient.setDataDataForKey = { _, key in
			if key == "profileSnapshotKeychainKey" {
				expectSetDataForProfile.fulfill()
			}
		}
		let environment = Onboarding.Environment(
			backgroundQueue: .unimplemented,
			keychainClient: keychainClient,
			mainQueue: .unimplemented
		)

		let nameOfFirstAccount = "Profile"
		let canProceed = true
		let store = TestStore(
			initialState: Onboarding.State(
				nameOfFirstAccount: nameOfFirstAccount,
				canProceed: canProceed
			),
			reducer: Onboarding.reducer,
			environment: environment
		)

		// when
		_ = await store.send(.internal(.user(.createProfile)))

		// then
		await store.receive(.internal(.system(.createProfile)))
		let profile = try await Profile.new(mnemonic: Mnemonic.generate())
		await store.receive(.internal(.system(.createdProfile(profile))))
		await store.receive(.coordinate(.onboardedWithProfile(profile)))
		waitForExpectations(timeout: 0.1)
	}
}
