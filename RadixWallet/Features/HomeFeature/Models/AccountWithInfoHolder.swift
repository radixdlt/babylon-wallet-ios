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

	public var isLegacyAccount: Bool { accountWithInfo.isLegacyAccount }
	public var isLedgerAccount: Bool { accountWithInfo.isLedgerAccount }
	public var isDappDefinitionAccount: Bool {
		get { accountWithInfo.isDappDefinitionAccount }
		set { accountWithInfo.isDappDefinitionAccount = newValue }
	}

	public var deviceFactorSourceControlled: DeviceFactorSourceControlled? {
		get { accountWithInfo.deviceFactorSourceControlled }
		set { accountWithInfo.deviceFactorSourceControlled = newValue }
	}

	public var mnemonicHandlingCallToAction: MnemonicHandling? {
		get { deviceFactorSourceControlled?.mnemonicHandlingCallToAction }
		set { deviceFactorSourceControlled?.mnemonicHandlingCallToAction = newValue }
	}

	public var importMnemonicNeeded: Bool {
		mnemonicHandlingCallToAction?.importMnemonicNeeded ?? false
	}

	public var exportMnemonicNeeded: Bool {
		mnemonicHandlingCallToAction?.exportMnemonicNeeded ?? false
	}
}

extension DeviceFactorSourceControlled {
	mutating func checkAccountAccessToMnemonic(xrdResource: OnLedgerEntity.OwnedFungibleResource? = nil) {
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.secureStorageClient) var secureStorageClient

		let importMnemonicNeeded = !secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(factorSourceID)
		if importMnemonicNeeded {
			mnemonicHandlingCallToAction = .mustBeImported
			return
		}

		guard let xrdResource else {
			mnemonicHandlingCallToAction = nil
			return
		}

		let hasValue = xrdResource.amount > .zero
		let hasAlreadyBackedUpMnemonic = userDefaults.getFactorSourceIDOfBackedUpMnemonics().contains(factorSourceID)
		let exportMnemonicNeeded = !hasAlreadyBackedUpMnemonic && hasValue

		guard exportMnemonicNeeded else {
			mnemonicHandlingCallToAction = nil
			return
		}
		mnemonicHandlingCallToAction = .shouldBeExported
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
