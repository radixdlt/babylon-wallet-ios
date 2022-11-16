import ComposableArchitecture
import TestUtils
import TransactionSigningFeature

@MainActor
final class TransactionSigningFeatureTests: TestCase {
	let store = TestStore(
		initialState: TransactionSigning.State(
			incomingMessageFromBrowser: try! .init(
				requestMethodWalletRequest: .placeholderSignTXRequets,
				browserExtensionConnection: .placeholder
			),
			addressOfSigner: try! .init(address: "deadbeef"),
			transactionManifest: .mock
		),
		reducer: TransactionSigning()
	)

	func testInitialState() {
		XCTAssertEqual(store.state.addressOfSigner, try! .init(address: "deadbeef"))
		XCTAssertEqual(store.state.transactionManifest, .mock)
	}

	func testSignTransaction() async {
		// Unhappy path - account lookup error
		struct LookupAccountByAddressError: LocalizedError, Equatable { let errorDescription: String? = "LookupAccountByAddressError" }
		store.dependencies.profileClient.lookupAccountByAddress = { _ in
			throw LookupAccountByAddressError()
		}
		let errorExpectation1 = expectation(description: "Error")
		store.dependencies.errorQueue.schedule = { error in
			XCTAssertEqual(error.localizedDescription, "LookupAccountByAddressError")
			errorExpectation1.fulfill()
		}
		_ = await store.send(.view(.signTransactionButtonTapped)) {
			$0.isSigningTX = true
		}
		await store.receive(.internal(.signTransactionResult(.failure(LookupAccountByAddressError())))) {
			$0.isSigningTX = false
		}

		// Unhappy path - sign TX error
		store.dependencies.profileClient.lookupAccountByAddress = { _ in
			.mocked0
		}
		struct SignTransactionError: LocalizedError, Equatable { let errorDescription: String? = "SignTransactionError" }
		store.dependencies.profileClient.signTransaction = { @Sendable _, _ in
			throw SignTransactionError()
		}
		let errorExpectation2 = expectation(description: "Error")
		store.dependencies.errorQueue.schedule = { error in
			XCTAssertEqual(error.localizedDescription, "SignTransactionError")
			errorExpectation2.fulfill()
		}
		_ = await store.send(.view(.signTransactionButtonTapped)) {
			$0.isSigningTX = true
		}
		await store.receive(.internal(.signTransactionResult(.failure(SignTransactionError())))) {
			$0.isSigningTX = false
		}

		// Happy path
		store.dependencies.profileClient.signTransaction = { @Sendable _, _ in
			"TXID"
		}
		_ = await store.send(.view(.signTransactionButtonTapped)) {
			$0.isSigningTX = true
		}
		await store.receive(.internal(.signTransactionResult(.success("TXID")))) {
			$0.isSigningTX = false
		}

		wait(for: [errorExpectation1, errorExpectation2], timeout: 0)
	}

	func testDismissView() async {
		_ = await store.send(.view(.closeButtonTapped))
		await store.receive(.delegate(.dismissView))
	}
}
