import Foundation

// MARK: - AccountWithInfo
public struct AccountWithInfo: Sendable, Hashable {
	public var account: Sargon.Account

	public var isDappDefinitionAccount: Bool = false
	public var deviceFactorSourceControlled: DeviceFactorSourceControlled?

	init(account: Sargon.Account) {
		self.account = account
		self.deviceFactorSourceControlled = Self.makeDeviceFactorSourceControlled(account)
	}

	private static func makeDeviceFactorSourceControlled(_ account: Sargon.Account) -> DeviceFactorSourceControlled? {
		switch account.securityState {
		case let .unsecured(unsecuredEntityControl):
			if unsecuredEntityControl.transactionSigning.factorSourceID.kind == .device {
				DeviceFactorSourceControlled(
					factorSourceID: unsecuredEntityControl.transactionSigning.factorSourceID
				)
			} else {
				nil
			}
		}
	}

	public var id: AccountAddress { account.address }
	public var isLegacyAccount: Bool { account.isLegacy }
	public var isLedgerAccount: Bool { account.isLedgerControlled }

	public var mnemonicHandlingCallToAction: MnemonicHandling? {
		deviceFactorSourceControlled?.mnemonicHandlingCallToAction
	}
}
