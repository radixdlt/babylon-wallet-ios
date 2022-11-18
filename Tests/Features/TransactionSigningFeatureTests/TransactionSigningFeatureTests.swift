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

	func testInitialState() {
		XCTAssertEqual(store.state.transactionManifest, .mock)
		XCTAssertNil(store.state.errorAlert)
	}

	func testSignTransaction() async {
		// Unhappy path - sign TX error
		store.dependencies.profileClient.lookupAccountByAddress = { _ in
			.mocked0
		}
		struct SignTransactionError: LocalizedError, Equatable { let errorDescription: String? = "SignTransactionError" }
		store.dependencies.profileClient.signTransaction = { @Sendable _ in
			throw SignTransactionError()
		}
		_ = await store.send(.view(.signTransactionButtonTapped)) {
			$0.isSigningTX = true
		}
		await store.receive(.internal(.signTransactionResult(.failure(SignTransactionError())))) {
			$0.isSigningTX = false
			$0.errorAlert = .init(title: .init("An error ocurred"), message: .init("SignTransactionError"))
		}
		_ = await store.send(.view(.errorAlertDismissButtonTapped)) {
			$0.errorAlert = nil
		}

		// Happy path
		store.dependencies.profileClient.signTransaction = { @Sendable _ in
			"TXID"
		}
		_ = await store.send(.view(.signTransactionButtonTapped)) {
			$0.isSigningTX = true
		}
		await store.receive(.internal(.signTransactionResult(.success("TXID")))) {
			$0.isSigningTX = false
		}
	}

	func testDismissView() async {
		_ = await store.send(.view(.closeButtonTapped))
		await store.receive(.delegate(.dismissed(request)))
	}
}
