@testable import CreateEntityFeature
import Cryptography
import FeatureTestingPrelude
import ProfileClient

@MainActor
final class CreationOfEntityTests: TestCase {
	let testScheduler = DispatchQueue.test

	func test__WHEN__account_is_created__THEN__it_is_added_to_profile() async throws {
		let account = OnNetwork.Account.previewValue0
		let store = TestStore(
			initialState: CreationOfEntity<OnNetwork.Account>.State(
				networkID: .nebunet,
				name: account.displayName,
				genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy.loadMnemonicFromKeychainForFactorSource(.previewValue)
			),
			reducer: CreationOfEntity<OnNetwork.Account>()
		) {
			$0.profileClient.createUnsavedVirtualEntity = { request in
				XCTAssertEqual(request.displayName, account.displayName)
				return account
			}
			$0.profileClient.addAccount = {
				XCTAssertEqual($0, account)
			}
		}
		await store.send(.internal(.view(.appeared)))
		await store.receive(.internal(.system(.createEntityResult(.success(account)))))
		await store.receive(.delegate(.createdEntity(account)))
	}

	func test__WHEN__creation_fails__THEN__error_is_propagated() async throws {
		let errorQueue = ActorIsolated<Set<NSError>>([])
		let createNewAccountError = NSError.testValue(domain: "Create New Account Request")
		let store = TestStore(
			initialState: CreationOfEntity<OnNetwork.Account>.State(
				networkID: .nebunet,
				name: "NeverCreated",
				genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy.loadMnemonicFromKeychainForFactorSource(.previewValue)
			),
			reducer: CreationOfEntity<OnNetwork.Account>()
		) {
			$0.profileClient.createUnsavedVirtualEntity = { request in
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

		let expectedErrors = Set([createNewAccountError])
		await store.send(.view(.appeared))
		await store.receive(.internal(.system(.createEntityResult(.failure(createNewAccountError)))))
		await errorQueue.withValue { errors in
			XCTAssertEqual(errors, expectedErrors)
		}
	}
}
