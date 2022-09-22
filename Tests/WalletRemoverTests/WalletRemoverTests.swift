import ComposableArchitecture
import TestUtils
import UserDefaultsClient
@testable import WalletRemover

@MainActor
final class WalletRemoverTests: TestCase {
	func test_removeWallet_whenRemoveWalletIsCalled_thenRemoveIsCalledOnDependency() async {
		// given
		let isRemoveCalled = ActorIsolated(false)
		var userDefaultsClient: UserDefaultsClient = .unimplemented
		userDefaultsClient.remove = { _ in
			await isRemoveCalled.setValue(true)
		}
		let sut = WalletRemover.live(userDefaultsClient: userDefaultsClient)

		// when
		await sut.removeWallet()

		// then
		await isRemoveCalled.withValue { XCTAssertNoDifference($0, true) }
	}
}
