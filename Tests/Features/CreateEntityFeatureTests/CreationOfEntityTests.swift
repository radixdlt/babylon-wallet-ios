@testable import CreateEntityFeature
import Cryptography
import FeatureTestingPrelude

@MainActor
final class CreationOfEntityTests: TestCase {
	func test__WHEN__account_is_created__THEN__it_is_added_to_profile() async throws {
		let account = OnNetwork.Account.previewValue0
		let initialState = CreationOfEntity<OnNetwork.Account>.State(
			curve: .curve25519,
			networkID: .nebunet,
			name: account.displayName,
			hdOnDeviceFactorSource: .previewValue
		)
		let store = TestStore(
			initialState: initialState,
			reducer: CreationOfEntity<OnNetwork.Account>()
		) {
			$0.accountsClient.createUnsavedVirtualAccount = { request in
				XCTAssertEqual(request.displayName, account.displayName)
				return account
			}
			$0.accountsClient.saveVirtualAccount = {
				XCTAssertEqual($0, account)
			}
		}
		await store.send(.view(.appeared))
		await store.receive(.internal(.createEntityResult(.success(account))))
		await store.receive(.delegate(.createdEntity(account)))
	}

	func test__WHEN__creation_fails__THEN__error_is_propagated() async throws {
		let errorQueue = ActorIsolated<Set<NSError>>([])
		let createNewAccountError = NSError.testValue(domain: "Create New Account Request")
		let initialState = CreationOfEntity<OnNetwork.Account>.State(
			curve: .curve25519,
			networkID: .nebunet,
			name: "NeverCreated",
			hdOnDeviceFactorSource: .previewValue
		)
		let store = TestStore(
			initialState: initialState,
			reducer: CreationOfEntity<OnNetwork.Account>()
		) {
			$0.accountsClient.createUnsavedVirtualAccount = { request in
				XCTAssertEqual(request.displayName, "NeverCreated")
				throw createNewAccountError
			}
			$0.errorQueue.schedule = { error in
				Task {
					await errorQueue.withValue { queue in
						queue.insert(error as NSError)
					}
				}
			}
		}

		await store.send(.view(.appeared))
		await store.receive(.internal(.createEntityResult(.failure(createNewAccountError))))
		await store.receive(.delegate(.createEntityFailed))
	}
}
