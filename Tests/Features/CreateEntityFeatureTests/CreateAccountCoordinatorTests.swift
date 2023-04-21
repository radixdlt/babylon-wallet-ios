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
			root: .step2_creationOfEntity(.init(
				networkID: nil,
				name: "Main",
				genesisFactorSourceSelection: .device(.previewValue)
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
		await store.send(.child(.path(.element(id: 2, action: .step2_creationOfEntity(.delegate(.createdEntity(account))))))) {
			$0.path.append(.step3_completion(.init(entity: account, config: initialState.config)))
		}

		await store.send(.child(.path(.element(id: 3, action: .step3_completion(.view(.goToDestination))))))
		await store.receive(.child(.path(.element(id: 3, action: .step3_completion(.delegate(.completed))))))
		await store.receive(.delegate(.completed))

		wait(for: [expectation], timeout: 0)
	}
}
