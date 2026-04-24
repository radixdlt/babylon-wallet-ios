import Sargon

// MARK: - AddressBookClient
struct AddressBookClient {
	var addEntry: AddEntry
	var entryByAddress: EntryByAddress
	var entriesOnCurrentNetwork: EntriesOnCurrentNetwork
	var deleteEntry: DeleteEntry
	var updateEntry: UpdateEntry
}

extension AddressBookClient {
	typealias AddEntry = @Sendable (Address, DisplayName, String?) async throws -> Void
	typealias EntryByAddress = @Sendable (Address) throws -> AddressBookEntry
	typealias EntriesOnCurrentNetwork = @Sendable () throws -> [AddressBookEntry]
	typealias DeleteEntry = @Sendable (Address) async throws -> Bool
	typealias UpdateEntry = @Sendable (Address, DisplayName, String?) async throws -> Bool
}

extension DependencyValues {
	var addressBookClient: AddressBookClient {
		get { self[AddressBookClient.self] }
		set { self[AddressBookClient.self] = newValue }
	}
}

extension Sequence<AddressBookEntry> {
	func sortedForDisplay() -> [AddressBookEntry] {
		sorted { lhs, rhs in
			let nameComparison = lhs.name.value.localizedCaseInsensitiveCompare(rhs.name.value)
			guard nameComparison == .orderedSame else {
				return nameComparison == .orderedAscending
			}

			return lhs.address.address.localizedStandardCompare(rhs.address.address) == .orderedAscending
		}
	}
}
