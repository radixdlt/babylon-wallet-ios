import ComposableArchitecture
import SharedModels
import TestUtils
import TransactionClient
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
			request: request,
			transactionWithLockFee: .mock
		),
		reducer: TransactionSigning()
	)

	func testInitialState() {
		XCTAssertEqual(store.state.transactionManifestWithoutLockFee, .mock)
	}

	func testSignTransaction() async {
		// Unhappy path - sign TX error
		store.dependencies.transactionClient.signAndSubmitTransaction = { @Sendable _ in
			.failure(.failedToCompileOrSign(.failedToCompileTXIntent))
		}
		let errorExpectation2 = expectation(description: "Error")
		store.dependencies.errorQueue.schedule = { anError in
			guard let error = anError as? TransactionFailure else {
				return XCTFail("Wrong error type")
			}
			XCTAssertEqual(error, .failedToCompileOrSign(.failedToCompileTXIntent))
			errorExpectation2.fulfill()
		}

		await store.send(.view(.signTransactionButtonTapped)) {
			$0.isSigningTX = true
		}
		await store.receive(.internal(.signTransactionResult(.failure(.failedToCompileOrSign(.failedToCompileTXIntent))))) {
			$0.isSigningTX = false
		}

		// Happy path
		store.dependencies.transactionClient.signAndSubmitTransaction = { @Sendable _ in
			.success("MOCKED_TX_ID")
		}
		await store.send(.view(.signTransactionButtonTapped)) {
			$0.isSigningTX = true
		}
		await store.receive(.internal(.signTransactionResult(.success("MOCKED_TX_ID")))) {
			$0.isSigningTX = false
		}

		wait(for: [errorExpectation2], timeout: 0)
	}

	func testReject() async {
		await store.send(.view(.closeButtonTapped))
		await store.receive(.delegate(.rejected(request)))
	}
}
