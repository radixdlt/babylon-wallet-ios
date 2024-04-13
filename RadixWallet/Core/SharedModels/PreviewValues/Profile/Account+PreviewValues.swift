#if DEBUG

extension Sargon.Account {
	public static let previewValue0: Self = .sampleMainnet

	public static let previewValue1: Self = .sampleMainnetOther
}

extension Sargon.Accounts {
	public static let previewValue = [Sargon.Account.previewValue0, Sargon.Account.previewValue1].asIdentified()
}

#endif // DEBUG
