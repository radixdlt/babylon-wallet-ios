#if DEBUG

extension Account {
	static let previewValue0: Self = .sampleMainnet

	static let previewValue1: Self = .sampleMainnetOther
}

extension Accounts {
	static let previewValue = [Account.previewValue0, Account.previewValue1].asIdentified()
}

#endif // DEBUG
