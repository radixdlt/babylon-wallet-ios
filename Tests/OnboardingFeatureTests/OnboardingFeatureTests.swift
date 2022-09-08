import ComposableArchitecture
@testable import OnboardingFeature
import Profile
import TestUtils
import Wallet

@MainActor
final class OnboardingFeatureTests: TestCase {
	private let environment = Onboarding.Environment(
		backgroundQueue: .unimplemented,
		mainQueue: .unimplemented,
		userDefaultsClient: .noop
	)

	func testCreateWallet() async {
		let profileName = "Profile"
		let store = TestStore(
			initialState: Onboarding.State(profileName: profileName, canProceed: true),
			reducer: Onboarding.reducer,
			environment: environment
		)

		let profile = try! Profile(name: profileName)
		let wallet: Wallet = .init(profile: profile, deviceFactorTypeMnemonic: "")
		_ = await store.send(.internal(.user(.createWallet)))
		await store.receive(.internal(.system(.createWallet)))
		await store.receive(.internal(.system(.createdWallet(wallet))))
		await store.receive(.coordinate(.onboardedWithWallet(wallet)))
	}
}
