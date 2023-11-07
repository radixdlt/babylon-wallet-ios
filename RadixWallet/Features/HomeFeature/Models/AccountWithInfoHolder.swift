// MARK: - AccountWithInfoHolder
/// Shared logic and state between Account Rows and Account Details.
public protocol AccountWithInfoHolder {
	var accountWithInfo: AccountWithInfo { get set }
}

extension AccountWithInfoHolder {
	public var account: Profile.Network.Account {
		get { accountWithInfo.account }
		set { accountWithInfo.account = newValue }
	}

	public var isLegacyAccount: Bool { accountWithInfo.isLedgerAccount }
	public var isLedgerAccount: Bool { accountWithInfo.isLedgerAccount }
	public var isDappDefinitionAccount: Bool {
		get { accountWithInfo.isDappDefinitionAccount }
		set { accountWithInfo.isDappDefinitionAccount = newValue }
	}

	public var deviceFactorSourceControlled: DeviceFactorSourceControlled? {
		get { accountWithInfo.deviceFactorSourceControlled }
		set { accountWithInfo.deviceFactorSourceControlled = newValue }
	}

	public var importMnemonicNeeded: Bool {
		accountWithInfo.importMnemonicNeeded
	}

	public var exportMnemonicNeeded: Bool {
		accountWithInfo.exportMnemonicNeeded
	}
}

extension DeviceFactorSourceControlled {
	mutating func checkAccountAccessToMnemonic(xrdResource: OnLedgerEntity.OwnedFungibleResource? = nil) {
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		importMnemonicNeeded = !secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(factorSourceID)

		guard let xrdResource else {
			return
		}

		let hasValue = xrdResource.amount > 0
		let hasAlreadyBackedUpMnemonic = userDefaultsClient.getFactorSourceIDOfBackedUpMnemonics().contains(factorSourceID)

		exportMnemonicNeeded = !hasAlreadyBackedUpMnemonic && hasValue
	}
}

extension AccountWithInfo {
	mutating func checkAccountAccessToMnemonic(xrdResource: OnLedgerEntity.OwnedFungibleResource? = nil) {
		deviceFactorSourceControlled?.checkAccountAccessToMnemonic(xrdResource: xrdResource)
	}
}

extension AccountWithInfoHolder {
	mutating func checkAccountAccessToMnemonic(portfolio: OnLedgerEntity.Account? = nil) {
		if let portfolio, account.address != portfolio.address {
			assertionFailure("Discrepancy, wrong owner")
		}
		checkAccountAccessToMnemonic(xrdResource: portfolio?.fungibleResources.xrdResource)
	}

	mutating func checkAccountAccessToMnemonic(xrdResource: OnLedgerEntity.OwnedFungibleResource? = nil) {
		accountWithInfo.checkAccountAccessToMnemonic(xrdResource: xrdResource)
	}
}
