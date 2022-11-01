import ComposableArchitecture
import KeychainClient
import Mnemonic
@testable import OnboardingFeature
import Profile
import TestUtils
import UserDefaultsClient

@MainActor
final class OnboardingNewProfileFeatureTests: TestCase {
	func test__GIVEN__no_profile__WHEN__new_profile_button_tapped__THEN__user_is_onboarded_with_new_profile() async throws {
		// given
		var keychainClient: KeychainClient = .unimplemented

		let setDataForProfileSnapshotExpectation = expectation(description: "setDataForKey for ProfileSnapshot should have been called")
		let profileSavedToKeychain = ActorIsolated<Profile?>(nil)

		keychainClient.setDataDataForKey = { data, key in
			if key == "profileSnapshotKeychainKey" {
				if let snapshot = try? JSONDecoder.iso8601.decode(ProfileSnapshot.self, from: data) {
					let profile = try? Profile(snapshot: snapshot)
					Task {
						await profileSavedToKeychain.setValue(profile)
						setDataForProfileSnapshotExpectation.fulfill()
					}
				}
			}
		}

		let store = TestStore(
			initialState: NewProfile.State(canProceed: true),
			reducer: NewProfile()
		)
		store.dependencies.keychainClient = keychainClient
		let mnemonic = try Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
		let generateMnemonicCalled = ActorIsolated<Bool>(false)

		let mnemonicGeneratorExpectation = expectation(description: "Generate Mnemonic should have been called")
		store.dependencies.mnemonicGenerator = { _, _ in
			Task {
				await generateMnemonicCalled.setValue(true)
				mnemonicGeneratorExpectation.fulfill()
			}
			return mnemonic
		}

		// when
		_ = await store.send(.internal(.user(.createProfile)))

		// then
		_ = await store.receive(.internal(.system(.createProfile))) {
			$0.isCreatingProfile = true
		}

		waitForExpectations(timeout: 1)
		await profileSavedToKeychain.withValue {
			if let profile = $0 {
				await store.receive(.internal(.system(.createdProfileResult(.success(profile))))) {
					$0.isCreatingProfile = false
				}
				await store.receive(.coordinate(.finishedCreatingNewProfile(profile)))
			}
		}
		await generateMnemonicCalled.withValue {
			XCTAssertTrue($0)
		}
	}
}
