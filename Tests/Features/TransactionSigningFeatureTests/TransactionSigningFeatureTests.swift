import FeatureTestingPrelude
import TransactionClient
@testable import TransactionSigningFeature

@MainActor
final class TransactionSigningFeatureTests: TestCase {
	lazy var store: TestStore = .init(
		initialState: TransactionSigning.State(
			transactionManifestWithoutLockFee: .mock,
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

		await store.send(.view(.signTransactionButtonTapped)) {
			$0.isSigningTX = true
		}
		await store.receive(.internal(.signTransactionResult(.failure(.failedToCompileOrSign(.failedToCompileTXIntent))))) {
			$0.isSigningTX = false
		}
		await store.receive(.delegate(.failed(.transactionFailure(.failedToCompileOrSign(.failedToCompileTXIntent)))))

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
	}
}
