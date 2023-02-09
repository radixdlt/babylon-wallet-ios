import FeatureTestingPrelude
@testable import TransactionSigningFeature

@MainActor
final class TransactionSigningFeatureTests: TestCase {
	let mockManifestWithoutLockFee = TransactionManifest(instructions: .string(
		"""
		# Withdraw XRD from account
		CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "withdraw_by_amount" Decimal("5.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");
		"""
	))

	let mockManifestWithLockFee = TransactionManifest(instructions: .string(
		"""
		CALL_METHOD
		 ComponentAddress("{this_account_component_address}")
		 "lock_fee"
		 Decimal("10");

		# Withdraw XRD from account
		CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "withdraw_by_amount" Decimal("5.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");
		"""
	))

	func testAddLockFeeToManifestOnAppearFailure() async {
		// given
		let store = TestStore(
			initialState: TransactionSigning.State(
				transactionManifestWithoutLockFee: mockManifestWithoutLockFee
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
				transactionManifestWithoutLockFee: mockManifestWithoutLockFee
			),
			reducer: TransactionSigning()
		) {
			$0.profileClient.getCurrentNetworkID = { .nebunet }
			$0.transactionClient.addLockFeeInstructionToManifest = { [self] _ in mockManifestWithLockFee }
			$0.errorQueue.schedule = { _ in }
		}

		// Unhappy path - sign TX error
		store.dependencies.transactionClient.signAndSubmitTransaction = { @Sendable _ in
			.failure(.failedToCompileOrSign(.failedToCompileTXIntent))
		}

		await store.send(.view(.appeared))
		await store.receive(
			/TransactionSigning.Action.internal .. /TransactionSigning.InternalAction.addLockFeeInstructionToManifestResult .. TaskResult.success
		) { [self] in
			$0.transactionWithLockFee = mockManifestWithLockFee
			$0.transactionWithLockFeeString = String(
				"""
				CALL_METHOD

					ComponentAddress("{this_account_component_address}")

					"lock_fee"

					Decimal("10");

				#
					Withdraw
					XRD
					from
					account
				CALL_METHOD
					ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064")
					"withdraw_by_amount"
					Decimal("5.0")
					ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");
				"""
			)
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
		await store.receive(.delegate(.signedTXAndSubmittedToGateway("MOCKED_TX_ID")))
	}
}
