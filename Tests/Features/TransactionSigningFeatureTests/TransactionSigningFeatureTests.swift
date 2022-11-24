import ComposableArchitecture
import SharedModels
import TestUtils
import TransactionSigningFeature

@MainActor
final class TransactionSigningFeatureTests: TestCase {
	let request = P2P.SignTransactionRequestToHandle(
		requestItem: .init(
			transactionManifest: .mock,
			version: .default,
			message: nil
		),
		parentRequest: .placeholder
	)

	lazy var store: TestStore = .init(
		initialState: TransactionSigning.State(
			request: request
		),
		reducer: TransactionSigning()
	)

//	func testInitialState() {
//		XCTAssertEqual(store.state.transactionManifest, .mock)
//	}
//
//	func testSignTransaction() async {
//		// Unhappy path - sign TX error
//		struct SignTransactionError: LocalizedError, Equatable { let errorDescription: String? = "SignTransactionError" }
//		store.dependencies.transactionClient.signTransaction = { @Sendable _ in
//			throw SignTransactionError()
//		}
//		let errorExpectation2 = expectation(description: "Error")
//		store.dependencies.errorQueue.schedule = { error in
//			XCTAssertEqual(error.localizedDescription, "SignTransactionError")
//			errorExpectation2.fulfill()
//		}
//		await store.send(.view(.signTransactionButtonTapped)) {
//			$0.isSigningTX = true
//		}
//		await store.receive(.internal(.signTransactionResult(.failure(SignTransactionError())))) {
//			$0.isSigningTX = false
//		}
//
//		// Happy path
//		store.dependencies.transactionClient.signTransaction = { @Sendable _ in
//			"TXID"
//		}
//		await store.send(.view(.signTransactionButtonTapped)) {
//			$0.isSigningTX = true
//		}
//		await store.receive(.internal(.signTransactionResult(.success("TXID")))) {
//			$0.isSigningTX = false
//		}
//
//		wait(for: [errorExpectation2], timeout: 0)
//	}

	func testDismissView() async {
		await store.send(.view(.closeButtonTapped))
		await store.receive(.delegate(.dismissed(request)))
	}
}
