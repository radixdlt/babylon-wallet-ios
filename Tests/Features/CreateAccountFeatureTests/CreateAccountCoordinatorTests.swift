@testable import CreateAccountFeature
import FeaturePrelude
import Profile
import TestUtils

@MainActor
final class CreateAccountCoordainatorTests: TestCase {
	func test_dismissCoordinator_onCreateAccountDismiss() async throws {
		let store = TestStore(
			initialState: .init(completionDestination: .home),
			reducer: CreateAccountCoordinator()
		)

		await store.send(.child(.createAccount(.delegate(.dismissCreateAccount))))
		await store.receive(.delegate(.dismissed))
	}

	func test_completionFlow() async throws {
		let initialState = CreateAccountCoordinator.State(completionDestination: .home)
		let account = OnNetwork.Account.testValue
		let isFirstAccount = false

		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccountCoordinator()
		)

		await store.send(.child(.createAccount(.delegate(.createdNewAccount(account: account, isFirstAccount: isFirstAccount))))) {
			$0.root = .accountCompletion(.init(account: account, isFirstAccount: isFirstAccount, destination: initialState.completionDestination))
		}
		await store.send(.child(.accountCompletion(.delegate(.completed))))
		await store.receive(.delegate(.completed))
	}
}
