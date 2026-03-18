import ComposableArchitecture
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

@MainActor
final class AddressBookFeatureTests: TestCase {
	func test_taskLoadsEntriesSortedForDisplay() async {
		var zebra = newAddressBookEntrySample()
		zebra.name = DisplayName(value: "Zebra")

		var alpha = newAddressBookEntrySampleOther()
		alpha.name = DisplayName(value: "alpha")

		let store = TestStore(
			initialState: AddressBook.State(),
			reducer: AddressBook.init
		) {
			$0.addressBookClient.entriesOnCurrentNetwork = { [zebra, alpha] }
		}

		await store.send(.view(.task))
		await store.receive(.internal(.loadedEntries([zebra, alpha]))) {
			$0.entries = [alpha, zebra]
		}
	}

	func test_editSaveUsesOriginalAddressAndTrimsFields() async throws {
		var entry = newAddressBookEntrySample()
		entry.address = .sample

		let updatedEntry = ActorIsolated<(AccountAddress, DisplayName, String?)?>(nil)
		let store = TestStore(
			initialState: AddressBookEntryForm.State(mode: .edit(entry)),
			reducer: AddressBookEntryForm.init
		) {
			$0.addressBookClient.updateEntry = { address, name, note in
				await updatedEntry.setValue((address, name, note))
				return true
			}
		}

		await store.send(.view(.addressChanged(AccountAddress.sampleOther.address))) {
			$0.address = AccountAddress.sampleOther.address
		}
		await store.send(.view(.nameChanged("  Alice  "))) {
			$0.name = "  Alice  "
		}
		await store.send(.view(.noteChanged("  Friend from exchange  "))) {
			$0.note = "  Friend from exchange  "
		}
		await store.send(.view(.saveButtonTapped))
		await store.receive(.delegate(.saved))

		let saved = try await XCTUnwrap(updatedEntry.value)
		XCTAssertEqual(saved.0, entry.address)
		XCTAssertEqual(saved.1, DisplayName(value: "Alice"))
		XCTAssertEqual(saved.2, "Friend from exchange")
	}

	func test_addSaveWithOwnedAccountShowsAlertAndDoesNotPersist() async {
		let addEntryWasCalled = ActorIsolated(false)
		let store = TestStore(
			initialState: AddressBookEntryForm.State(mode: .add),
			reducer: AddressBookEntryForm.init
		) {
			$0.accountsClient.getAccountsOnCurrentNetwork = { [.sample] }
			$0.addressBookClient.addEntry = { _, _, _ in
				await addEntryWasCalled.setValue(true)
				return true
			}
		}

		await store.send(.view(.addressChanged(AccountAddress.sample.address))) {
			$0.address = AccountAddress.sample.address
		}
		await store.send(.view(.nameChanged("Owned account"))) {
			$0.name = "Owned account"
		}
		await store.send(.view(.saveButtonTapped))
		await store.receive(.internal(.ownAccountAddressNotAllowed))

		guard case .ownAccountAddressNotAllowedAlert? = store.state.destination else {
			return XCTFail("Expected own-account alert destination")
		}
		await XCTAssertFalse(addEntryWasCalled.value)
	}
}
