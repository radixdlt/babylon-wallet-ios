import FeatureTestingPrelude
@testable import TransactionSigningFeature

@MainActor
final class TransactionSigningFeatureTests: TestCase {
	func testAddLockFeeToManifestOnAppearFailure() async {
		// given
		let store = TestStore(
			initialState: TransactionSigning.State(
				transactionManifestWithoutLockFee: .mock
			),
			reducer: TransactionSigning()
		) {
			$0.profileClient.getCurrentNetworkID = { .nebunet }
			$0.transactionClient.addLockFeeInstructionToManifest = { _ in throw NoopError() }
			$0.errorQueue.schedule = { XCTAssertEqual($0 as? NoopError, NoopError()) }
		}

		// when
		await store.send(.view(.appeared))

		// then
		await store.receive(.internal(.addLockFeeInstructionToManifestResult(.failure(NoopError()))))
		await store.receive(.delegate(.failed(.prepareTransactionFailure(.addTransactionFee(NoopError())))))
	}

	func testSignTransaction() async {
		let store = TestStore(
			initialState: TransactionSigning.State(
				transactionManifestWithoutLockFee: .mock
			),
			reducer: TransactionSigning()
		) {
			$0.profileClient.getCurrentNetworkID = { .nebunet }
			$0.transactionClient.addLockFeeInstructionToManifest = { _ in .mock }
			$0.errorQueue.schedule = { _ in }
		}
		store.exhaustivity = .off(showSkippedAssertions: true)

		// Unhappy path - sign TX error
		store.dependencies.transactionClient.signAndSubmitTransaction = { @Sendable _ in
			.failure(.failedToCompileOrSign(.failedToCompileTXIntent))
		}

		await store.send(.view(.appeared))
		await store.receive(/TransactionSigning.Action.internal .. /TransactionSigning.InternalAction.addLockFeeInstructionToManifestResult .. TaskResult.success) {
			$0.transactionWithLockFee = .mock
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
