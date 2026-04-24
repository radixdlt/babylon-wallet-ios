import Sargon

extension AddressBookClient: TestDependencyKey {
	static let previewValue = Self(
		addEntry: { _, _, _ in },
		entryByAddress: { _ in throw NoopError() },
		entriesOnCurrentNetwork: { [] },
		deleteEntry: { _ in true },
		updateEntry: { _, _, _ in true }
	)

	static let testValue = Self(
		addEntry: unimplemented("\(Self.self).addEntry"),
		entryByAddress: unimplemented("\(Self.self).entryByAddress"),
		entriesOnCurrentNetwork: unimplemented("\(Self.self).entriesOnCurrentNetwork"),
		deleteEntry: unimplemented("\(Self.self).deleteEntry"),
		updateEntry: unimplemented("\(Self.self).updateEntry")
	)
}
