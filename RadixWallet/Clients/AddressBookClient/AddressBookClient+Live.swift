import Sargon

// MARK: - AddressBookClient + DependencyKey
extension AddressBookClient: DependencyKey {
	typealias Value = AddressBookClient

	static let liveValue: Self = .live()

	static func live() -> Self {
		Self(
			addEntry: { target, name, note in
				try await SargonOs.shared.addAddressBookEntry(target: target, name: name, note: note)
			},
			entryByTarget: { target in
				try SargonOs.shared.addressBookEntry(target: target)
			},
			entriesOnCurrentNetwork: {
				try SargonOs.shared.addressBookOnCurrentNetwork()
			},
			deleteEntry: { target in
				try await SargonOs.shared.deleteAddressBookEntry(target: target)
			},
			updateEntry: { target, name, note in
				try await SargonOs.shared.updateAddressBookEntry(target: target, name: name, note: note)
			}
		)
	}
}
