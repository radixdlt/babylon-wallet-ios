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
		var keychainClient: KeychainClient = .testValue

		let setDataForProfileSnapshotExpectation = expectation(description: "setDataForKey for ProfileSnapshot should have been called")
		let profileSavedToKeychain = ActorIsolated<Profile?>(nil)

		keychainClient.updateDataForKey = { data, key, _, _ in
			if key == "profileSnapshotKeychainKey" {
				if let snapshot = try? JSONDecoder.liveValue().decode(ProfileSnapshot.self, from: data) {
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
		store.dependencies.profileClient.createNewProfile = { req in
			try! await Profile.new(
				networkAndGateway: req.networkAndGateway,
				mnemonic: req.curve25519FactorSourceMnemonic
			)
		}

		store.dependencies.transactionClient.signAndSubmitTransaction = { _ in .success(.placeholder) }
		store.dependencies.keychainClient = keychainClient
		let mnemonic = try Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
		let generateMnemonicCalled = ActorIsolated<Bool>(false)

		let mnemonicGeneratorExpectation = expectation(description: "Generate Mnemonic should have been called")
		store.dependencies.mnemonicGenerator.generate = { _, _ in
			Task {
				await generateMnemonicCalled.setValue(true)
				mnemonicGeneratorExpectation.fulfill()
			}
			return mnemonic
		}

		// when
		await store.send(.internal(.view(.createProfileButtonPressed)))

		// then
		await store.receive(.internal(.system(.createProfile))) {
			$0.isCreatingProfile = true
		}

		waitForExpectations(timeout: 1)
		await profileSavedToKeychain.withValue {
			if let profile = $0 {
				await store.receive(.internal(.system(.createdProfileResult(.success(profile))))) {
					$0.isCreatingProfile = false
				}
				await store.receive(.delegate(.finishedCreatingNewProfile(profile)))
			}
		}
		await generateMnemonicCalled.withValue {
			XCTAssertTrue($0)
		}
	}
}
