import Sargon

// MARK: - AddressBookClient
struct AddressBookClient {
	var addEntry: AddEntry
	var entryByTarget: EntryByTarget
	var entriesOnCurrentNetwork: EntriesOnCurrentNetwork
	var deleteEntry: DeleteEntry
	var updateEntry: UpdateEntry
}

extension AddressBookClient {
	typealias AddEntry = @Sendable (AddressBookEntryTarget, DisplayName, String?) async throws -> Void
	typealias EntryByTarget = @Sendable (AddressBookEntryTarget) throws -> AddressBookEntry
	typealias EntriesOnCurrentNetwork = @Sendable () throws -> [AddressBookEntry]
	typealias DeleteEntry = @Sendable (AddressBookEntryTarget) async throws -> Bool
	typealias UpdateEntry = @Sendable (AddressBookEntryTarget, DisplayName, String?) async throws -> Bool
}

extension AddressBookClient {
	/// The entry naming `address`.
	func entryByAddress(_ address: Address) throws -> AddressBookEntry {
		try entryByTarget(.globalAddress(value: address))
	}
}

extension AddressBookEntryTarget {
	/// The address it names, if it names an address and not a non-fungible.
	var address: Address? {
		if case let .globalAddress(value) = self {
			value
		} else {
			nil
		}
	}

	/// How it is written, e.g. typed into the address book form.
	var rawString: String {
		switch self {
		case let .globalAddress(value): value.address
		case let .nonFungible(value): value.toRawString()
		}
	}
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

			return lhs.target.rawString.localizedStandardCompare(rhs.target.rawString) == .orderedAscending
		}
	}
}
