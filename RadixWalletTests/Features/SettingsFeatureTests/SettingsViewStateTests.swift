import Foundation
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - SettingsViewStateTests
final class SettingsViewStateTests: TestCase {
	func testAppVersion() {
		withDependencies {
			$0.bundleInfo = .init(
				bundleIdentifier: "",
				name: "",
				displayName: "",
				spokenName: "",
				shortVersion: "4.2.0",
				version: "5"
			)
		} operation: {
			let sut = Settings.ViewState(state: .init())
			XCTAssertEqual(sut.appVersion, "App version: 4.2.0 (5)")
		}
	}
}

// MARK: - RawManifestTransactionTests
@MainActor
final class RawManifestTransactionTests: TestCase {
	func test_sendTapped_withEmptyManifest_doesNothing() async {
		let didCallInteraction = ActorIsolated(false)

		let store = TestStore(
			initialState: RawManifestTransaction.State(),
			reducer: RawManifestTransaction.init
		) {
			$0.dappInteractionClient.addWalletInteraction = { _, _ in
				await didCallInteraction.setValue(true)
				return .init(
					p2pResponse: .dapp(.failure(.init(
						interactionId: "noop",
						error: .rejectedByUser,
						message: nil
					)))
				)
			}
		}

		await store.send(.view(.sendTapped))
		await XCTAssertFalse(didCallInteraction.value)
	}

	func test_sendTapped_withValidManifest_callsDedicatedInteraction_andCompletes() async {
		let didCallInteraction = ActorIsolated(false)
		let interactionKind = ActorIsolated<DappInteractionClient.WalletInteraction?>(nil)

		var state = RawManifestTransaction.State()
		state.manifest = "DROP_ALL_PROOFS;"

		let store = TestStore(
			initialState: state,
			reducer: RawManifestTransaction.init
		) {
			$0.gatewaysClient.getCurrentGateway = { .stokenet }
			$0.dappInteractionClient.addWalletInteraction = { _, interaction in
				await didCallInteraction.setValue(true)
				await interactionKind.setValue(interaction)
				return .init(
					p2pResponse: .dapp(.success(.init(
						interactionId: "raw_manifest_test",
						items: .transaction(.init(send: .init(transactionIntentHash: .sample)))
					)))
				)
			}
		}

		await store.send(.view(.sendTapped)) {
			$0.isSending = true
		}
		await store.receive(.internal(.interactionCompleted)) {
			$0.isSending = false
		}

		await XCTAssertTrue(didCallInteraction.value)
		await XCTAssertEqual(interactionKind.value, .rawManifestTransaction)
	}

	func test_sendTapped_withInvalidManifest_schedulesError_andDoesNotStartInteraction() async {
		let didCallInteraction = ActorIsolated(false)
		let didScheduleError = ActorIsolated(false)

		var state = RawManifestTransaction.State()
		state.manifest = "INVALID MANIFEST"

		let store = TestStore(
			initialState: state,
			reducer: RawManifestTransaction.init
		) {
			$0.gatewaysClient.getCurrentGateway = { .stokenet }
			$0.errorQueue.schedule = { _ in
				Task {
					await didScheduleError.setValue(true)
				}
			}
			$0.dappInteractionClient.addWalletInteraction = { _, _ in
				await didCallInteraction.setValue(true)
				return .init(
					p2pResponse: .dapp(.failure(.init(
						interactionId: "noop",
						error: .rejectedByUser,
						message: nil
					)))
				)
			}
		}

		await store.send(.view(.sendTapped)) {
			$0.isSending = true
		}
		await store.receive(.internal(.interactionCompleted)) {
			$0.isSending = false
		}

		await XCTAssertFalse(didCallInteraction.value)
		await XCTAssertTrue(didScheduleError.value)
	}

	func test_sendTapped_whenInteractionReturnsFailure_resetsLoadingState() async {
		var state = RawManifestTransaction.State()
		state.manifest = "DROP_ALL_PROOFS;"

		let store = TestStore(
			initialState: state,
			reducer: RawManifestTransaction.init
		) {
			$0.gatewaysClient.getCurrentGateway = { .stokenet }
			$0.dappInteractionClient.addWalletInteraction = { _, _ in
				.init(
					p2pResponse: .dapp(.failure(.init(
						interactionId: "raw_manifest_test",
						error: .rejectedByUser,
						message: nil
					)))
				)
			}
		}

		await store.send(.view(.sendTapped)) {
			$0.isSending = true
		}
		await store.receive(.internal(.interactionCompleted)) {
			$0.isSending = false
		}
	}
}
