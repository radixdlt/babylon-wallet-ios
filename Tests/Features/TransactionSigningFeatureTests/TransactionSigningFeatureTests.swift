import ComposableArchitecture
import TestUtils
import TransactionSigningFeature

@MainActor
final class TransactionSigningFeatureTests: TestCase {
	let store = TestStore(
		initialState: TransactionSigning.State(
			address: "123",
			transactionManifest: .mock
		),
		reducer: TransactionSigning()
	)

	func testInitialState() {
		XCTAssertEqual(store.state.address, "123")
		XCTAssertEqual(store.state.transactionManifest, .mock)
		XCTAssertNil(store.state.errorAlert)
	}

	func testSignTransaction() async {
		// Unhappy path - account lookup error
		struct LookupAccountByAddressError: LocalizedError, Equatable { let errorDescription: String? = "LookupAccountByAddressError" }
		store.dependencies.profileClient.lookupAccountByAddress = { _ in
			throw LookupAccountByAddressError()
		}
		_ = await store.send(.view(.signTransactionButtonTapped))
		await store.receive(.internal(.addressLookupFailed(LookupAccountByAddressError() as NSError))) {
			$0.errorAlert = .init(title: .init("An error ocurred"), message: .init("LookupAccountByAddressError"))
		}
		_ = await store.send(.view(.errorAlertDismissButtonTapped)) {
			$0.errorAlert = nil
		}

		// Unhappy path - sign TX error
		store.dependencies.profileClient.lookupAccountByAddress = { _ in
			.mocked0
		}
		struct SignTransactionError: LocalizedError, Equatable { let errorDescription: String? = "SignTransactionError" }
		store.dependencies.profileClient.signTransaction = { _, _ in
			throw SignTransactionError()
		}
		_ = await store.send(.view(.signTransactionButtonTapped))
		await store.receive(.internal(.signTransactionResult(.failure(SignTransactionError())))) {
			$0.errorAlert = .init(title: .init("An error ocurred"), message: .init("SignTransactionError"))
		}
		_ = await store.send(.view(.errorAlertDismissButtonTapped)) {
			$0.errorAlert = nil
		}

		// Happy path
		store.dependencies.profileClient.signTransaction = { _, _ in
			"TXID"
		}
		_ = await store.send(.view(.signTransactionButtonTapped))
		await store.receive(.internal(.signTransactionResult(.success("TXID"))))
	}

	func testDismissView() async {
		_ = await store.send(.view(.closeButtonTapped))
		await store.receive(.delegate(.dismissView))
	}
}
