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

		await fulfillment(of: [expectation], timeout: 0.1)
	}

	func test_completionFlow() async throws {
		let config = CreateEntityConfig(
			purpose: .newAccountFromHome
		)
		let expectation = expectation(description: "dismiss() called")

		var initialState = CreateAccountCoordinator.State(
			config: config
		)
		initialState.path.append(.step1_nameNewEntity(.init(config: config)))
		initialState.path.append(.step2_creationOfEntity(.init(
			networkID: nil,
			name: "Main",
			genesisFactorSourceSelection: .device(.previewValue)
		)))

		let account = Profile.Network.Account.previewValue0

		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccountCoordinator()
		) {
			$0.dismiss = .init { expectation.fulfill() }
		}
		await store.send(.child(.path(.element(id: 1, action: .step2_creationOfEntity(.delegate(.createdEntity(account))))))) {
			$0.path.append(.step3_completion(.init(entity: account, config: config)))
		}

		await store.send(.child(.path(.element(id: 2, action: .step3_completion(.view(.goToDestination))))))
		await store.receive(.child(.path(.element(id: 2, action: .step3_completion(.delegate(.completed))))))
		await store.receive(.delegate(.completed))

		await fulfillment(of: [expectation], timeout: 0.1)
	}
}
