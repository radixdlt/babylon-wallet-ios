#if DEBUG

extension Account {
	public static let previewValue0: Self = .sampleMainnet

	public static let previewValue1: Self = .sampleMainnetOther
}

extension Accounts {
	public static let previewValue = [Account.previewValue0, Account.previewValue1].asIdentified()
}

#endif // DEBUG
