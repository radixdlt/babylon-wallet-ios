@testable import Radix_Wallet_Dev
import XCTest

@MainActor
final class MainFeatureTests: TestCase {
	func test_displayAndDismissSettings() async {
		// given
		let store = TestStore(initialState: Main.State(home: .previewValue)) {
			Main()
				.dependency(\.userDefaults, .noop)
		}

		// when
		await store.send(.child(.home(.delegate(.displaySettings)))) {
			// then
			$0.destination = .settings(.init())
		}

		// when
		await store.send(.child(.destination(.dismiss))) {
			// then
			$0.destination = nil
		}
	}

	func test_displayTestBanner() async {
		// given
		let store = TestStore(initialState: Main.State(home: .previewValue)) {
			Main()
				.dependency(\.userDefaults, .noop)
				.dependency(\.gatewaysClient.currentGatewayValues) { AsyncLazySequence([.stokenet]).eraseToAnyAsyncSequence() }
		}

		XCTAssertFalse(store.state.showIsUsingTestnetBanner)

		await store.send(.view(.task))

		await store.receive(.internal(.currentGatewayChanged(to: .stokenet))) {
			$0.isOnMainnet = false
		}
		XCTAssertTrue(store.state.showIsUsingTestnetBanner)
	}
}
