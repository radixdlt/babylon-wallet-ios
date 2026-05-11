import Sargon

// MARK: - AddressBookClient + DependencyKey
extension AddressBookClient: DependencyKey {
	typealias Value = AddressBookClient

	static let liveValue: Self = .live()

	static func live() -> Self {
		Self(
			addEntry: { address, name, note in
				try await SargonOs.shared.addAddressBookEntry(address: address, name: name, note: note)
			},
			entryByAddress: { address in
				try SargonOs.shared.addressBookEntryByAddress(address: address)
			},
			entriesOnCurrentNetwork: {
				try SargonOs.shared.addressBookOnCurrentNetwork()
			},
			deleteEntry: { address in
				try await SargonOs.shared.deleteAddressBookEntry(address: address)
			},
			updateEntry: { address, name, note in
				try await SargonOs.shared.updateAddressBookEntry(address: address, name: name, note: note)
			}
		)
	}
}
