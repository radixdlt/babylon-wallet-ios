import ComposableArchitecture
@testable import OnboardingFeature
import Profile
import TestUtils
import UserDefaultsClient
import Wallet

@MainActor
final class OnboardingFeatureTests: TestCase {
	func test_createWallet_whenTappedOnCreateWalletButton_thenCreateWallet() async {
		// given
		let isSetDataCalled = ActorIsolated(false)
		var userDefaultsClient: UserDefaultsClient = .unimplemented
		userDefaultsClient.setData = { _, _ in
			await isSetDataCalled.setValue(true)
		}
		let environment = Onboarding.Environment(
			backgroundQueue: .unimplemented,
			mainQueue: .unimplemented,
			userDefaultsClient: userDefaultsClient
		)

		let profileName = "Profile"
		let canProceed = true
		let store = TestStore(
			initialState: Onboarding.State(
				profileName: profileName,
				canProceed: canProceed
			),
			reducer: Onboarding.reducer,
			environment: environment
		)

		// when
		_ = await store.send(.internal(.user(.createWallet)))

		// then
		await store.receive(.internal(.system(.createWallet)))
		do {
			let profile = try Profile(name: profileName)
			let wallet: Wallet = .init(profile: profile, deviceFactorTypeMnemonic: "")
			await store.receive(.internal(.system(.createdWallet(wallet))))
			await store.receive(.coordinate(.onboardedWithWallet(wallet)))
			await isSetDataCalled.withValue { XCTAssertNoDifference($0, true) }
		} catch {
			XCTFail("No profile")
		}
	}

	func test_binding_whenProfileNameIsNotEmpty_thenCanProceedWithWalletCreation() {
		// given
		let store = TestStore(
			initialState: .placeholder,
			reducer: Onboarding.reducer,
			environment: .unimplemented
		)

		// when
		let canProceed = !store.state.profileName.isEmpty

		// then
		XCTAssertEqual(store.state.canProceed, canProceed)
	}
}
