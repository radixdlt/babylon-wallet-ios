import Foundation

// MARK: - AccountWithInfo
public struct AccountWithInfo: Sendable, Hashable {
	public var account: Profile.Network.Account {
		didSet {
			self.deviceFactorSourceControlled = Self.makeDeviceFactorSourceControlled(account)
		}
	}

	public var isDappDefinitionAccount: Bool = false
	public var deviceFactorSourceControlled: DeviceFactorSourceControlled?

	init(account: Profile.Network.Account) {
		self.account = account
		self.deviceFactorSourceControlled = Self.makeDeviceFactorSourceControlled(account)
	}

	private static func makeDeviceFactorSourceControlled(_ account: Profile.Network.Account) -> DeviceFactorSourceControlled? {
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
	public var isLegacyAccount: Bool { account.isOlympiaAccount }
	public var isLedgerAccount: Bool { account.isLedgerAccount }

	public var mnemonicHandlingCallToAction: MnemonicHandling? {
		deviceFactorSourceControlled?.mnemonicHandlingCallToAction
	}
}
