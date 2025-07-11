@testable import Radix_Wallet_Dev
import Sargon
import XCTest

@MainActor
final class MainFeatureTests: TestCase {
	func test_displayTestBanner() async {
		// given
		let store = TestStore(initialState: Main.State(
			home: .previewValue,
			dAppsDirectory: .init(),
			discover: .init(),
			settings: .init()
		)) {
			Main()
//				.dependency(\.userDefaults, .noop)
				.dependency(\.cloudBackupClient, .noop)
				.dependency(\.gatewaysClient.currentGatewayValues) { AsyncLazySequence([.stokenet]).eraseToAnyAsyncSequence() }
				.dependency(\.resetWalletClient, .noop)
				.dependency(\.securityCenterClient, .noop)
				.dependency(\.deepLinkHandlerClient, .noop)
				.dependency(\.accountLockersClient, .noop)
				.dependency(\.radixConnectClient, .noop)
		}

		XCTAssertFalse(store.state.showIsUsingTestnetBanner)

		await store.send(.view(.task))

		await store.receive(.internal(.currentGatewayChanged(to: .stokenet))) {
			$0.isOnMainnet = false
		}
		XCTAssertTrue(store.state.showIsUsingTestnetBanner)
	}
}
