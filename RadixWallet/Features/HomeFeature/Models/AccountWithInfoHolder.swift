// MARK: - AccountWithInfoHolder
/// Shared logic and state between Account Rows and Account Details.
protocol AccountWithInfoHolder {
	var accountWithInfo: AccountWithInfo { get set }
}

extension AccountWithInfoHolder {
	var account: Account {
		get { accountWithInfo.account }
		set { accountWithInfo.account = newValue }
	}

	var isLegacyAccount: Bool { accountWithInfo.isLegacyAccount }
	var isLedgerAccount: Bool { accountWithInfo.isLedgerAccount }
	var isDappDefinitionAccount: Bool {
		get { accountWithInfo.isDappDefinitionAccount }
		set { accountWithInfo.isDappDefinitionAccount = newValue }
	}
}
