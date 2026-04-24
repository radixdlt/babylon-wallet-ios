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
		entry.address = ResourceAddress.sample.asGeneral

		let updatedEntry = ActorIsolated<(Address, DisplayName, String?)?>(nil)
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

	func test_addSaveWithNonAccountAddressPersistsGenericAddress() async throws {
		let savedEntry = ActorIsolated<(Address, DisplayName, String?)?>(nil)
		let store = TestStore(
			initialState: AddressBookEntryForm.State(mode: .add),
			reducer: AddressBookEntryForm.init
		) {
			$0.addressBookClient.addEntry = { address, name, note in
				await savedEntry.setValue((address, name, note))
			}
		}

		await store.send(.view(.addressChanged(ResourceAddress.sample.address))) {
			$0.address = ResourceAddress.sample.address
		}
		await store.send(.view(.nameChanged("  XRD  "))) {
			$0.name = "  XRD  "
		}
		await store.send(.view(.noteChanged("  Token resource  "))) {
			$0.note = "  Token resource  "
		}
		await store.send(.view(.saveButtonTapped))
		await store.receive(.delegate(.saved))

		let saved = try await XCTUnwrap(savedEntry.value)
		XCTAssertEqual(saved.0, ResourceAddress.sample.asGeneral)
		XCTAssertEqual(saved.1, DisplayName(value: "XRD"))
		XCTAssertEqual(saved.2, "Token resource")
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

	func test_transferRecipientAddressBookEntriesAreLimitedToAccountAddresses() {
		var accountEntry = newAddressBookEntrySample()
		accountEntry.address = AccountAddress.sampleOther.asGeneral

		var ownAccountEntry = newAddressBookEntrySampleOther()
		ownAccountEntry.address = AccountAddress.sample.asGeneral

		var resourceEntry = newAddressBookEntrySample()
		resourceEntry.address = ResourceAddress.sample.asGeneral

		var state = ChooseTransferRecipient.State(
			networkID: .mainnet,
			chooseAccounts: .init(
				context: .assetTransfer,
				filteredAccounts: [AccountAddress.sample]
			)
		)
		state.addressBookEntries = [accountEntry, ownAccountEntry, resourceEntry]

		XCTAssertEqual(state.selectableAddressBookEntries, [accountEntry])
	}
}
