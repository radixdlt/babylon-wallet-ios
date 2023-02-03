@testable import CreateEntityFeature
import FeatureTestingPrelude

@MainActor
final class CreateAccountCoordinatorTests: TestCase {
	func test_dismissCoordinator_onCreateAccountDismiss() async throws {
		let store = TestStore(
			initialState: CreateEntityCoordinator.State(config: .init(isFirstEntity: false, canBeDismissed: true, navigationButtonCTA: .goHome)),
			reducer: CreateAccountCoordinator()
		)

		await store.send(.view(.dismiss))
		await store.receive(.delegate(.dismissed))
	}

	func test_completionFlow() async throws {
		let isFirstAccount = false
		let config = CreateEntityConfig(
			isFirstEntity: isFirstAccount,
			canBeDismissed: true,
			navigationButtonCTA: .goHome
		)
		let initialState = CreateAccountCoordinator.State(
			step: .step2_creationOfEntity(.init(
				networkID: nil,
				name: "Main",
				genesisFactorInstanceDerivationStrategy: .loadMnemonicFromKeychainForFactorSource(.previewValue)
			)),
			config: config
		)
		let account = OnNetwork.Account.testValue

		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccountCoordinator()
		)

		await store.send(.child(.step2_creationOfEntity(.delegate(.createdEntity(account))))) {
			$0.step = .step3_completion(.init(entity: account, config: initialState.config))
		}
		await store.send(.child(.step3_completion(.view(.goToDestination))))
		await store.receive(.child(.step3_completion(.delegate(.completed))))
		await store.receive(.delegate(.completed))
	}
}
