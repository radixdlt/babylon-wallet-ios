@testable import CreateEntityFeature
import FeatureTestingPrelude

@MainActor
final class CreateAccountCoordinatorTests: TestCase {
	func test_dismissCoordinator_onCreateAccountDismiss() async throws {
		let expectation = expectation(description: "dismiss() called")
		let store = TestStore(
			initialState: CreateEntityCoordinator.State(
				config: .init(purpose: .newAccountFromHome)
			),
			reducer: CreateAccountCoordinator()
		) {
			$0.dismiss = .init { expectation.fulfill() }
		}

		await store.send(.view(.closeButtonTapped))
		await store.receive(.delegate(.dismissed))

		wait(for: [expectation], timeout: 0)
	}

	func test_completionFlow() async throws {
		let isFirstAccount = false
		let config = CreateEntityConfig(
			purpose: .newAccountFromHome
		)
		let expectation = expectation(description: "dismiss() called")

		let initialState = CreateAccountCoordinator.State(
			step: .step3_creationOfEntity(.init(
				curve: .curve25519,
				networkID: nil,
				name: "Main",
				hdOnDeviceFactorSource: .previewValue
			)),
			config: config
		)
		let account = Profile.Network.Account.previewValue0

		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccountCoordinator()
		) {
			$0.dismiss = .init { expectation.fulfill() }
		}

		await store.send(.child(.step3_creationOfEntity(.delegate(.createdEntity(account))))) {
			$0.step = .step4_completion(.init(entity: account, config: initialState.config))
		}
		await store.send(.child(.step4_completion(.view(.goToDestination))))
		await store.receive(.child(.step4_completion(.delegate(.completed))))
		await store.receive(.delegate(.completed))

		wait(for: [expectation], timeout: 0)
	}
}
