// MARK: - AccountWithInfoHolder
/// Shared logic and state between Account Rows and Account Details.
public protocol AccountWithInfoHolder {
	var accountWithInfo: AccountWithInfo { get set }
}

extension AccountWithInfoHolder {
	public var account: Account {
		get { accountWithInfo.account }
		set { accountWithInfo.account = newValue }
	}

	public var isLegacyAccount: Bool { accountWithInfo.isLegacyAccount }
	public var isLedgerAccount: Bool { accountWithInfo.isLedgerAccount }
	public var isDappDefinitionAccount: Bool {
		get { accountWithInfo.isDappDefinitionAccount }
		set { accountWithInfo.isDappDefinitionAccount = newValue }
	}
}
