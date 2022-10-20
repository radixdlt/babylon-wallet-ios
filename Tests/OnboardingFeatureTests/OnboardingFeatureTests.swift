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

		let expectActorIsolated = expectation(description: "ActorIsolated<Profile?> to have set value")
		let profileSavedToKeychain = ActorIsolated<Profile?>(nil)

		keychainClient.setDataDataForKey = { data, key in
			if key == "profileSnapshotKeychainKey" {
				if let snapshot = try? JSONDecoder.iso8601.decode(ProfileSnapshot.self, from: data) {
					let profile = try? Profile(snapshot: snapshot)
					Task {
						await profileSavedToKeychain.setValue(profile)
						expectActorIsolated.fulfill()
					}
				}
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

		waitForExpectations(timeout: 1)
		await profileSavedToKeychain.withValue {
			if let profile = $0 {
				await store.receive(.internal(.system(.createdProfile(profile))))
				await store.receive(.coordinate(.onboardedWithProfile(profile)))
			}
		}
	}
}
