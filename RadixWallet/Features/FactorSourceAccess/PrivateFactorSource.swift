import Foundation

// MARK: - PrivateFactorSource
/// An enum containing the necessary information to use a given `FactorSource`.
///
/// This becomes handy to unify factor sources with the private input resolved by their access UI.
enum PrivateFactorSource: Hashable {
	case device(DeviceFactorSource, MnemonicWithPassphrase)
	case ledger(LedgerHardwareWalletFactorSource)
	case arculusCard(ArculusCardFactorSource, _ pin: String)
	case offDeviceMnemonic(OffDeviceMnemonicFactorSource, MnemonicWithPassphrase)
	case password(PasswordFactorSource, MnemonicWithPassphrase)
}

extension PrivateFactorSource {
	var factorSource: FactorSource {
		switch self {
		case let .device(device, _):
			device.asGeneral
		case let .ledger(ledger):
			ledger.asGeneral
		case let .arculusCard(arculusCard, _):
			arculusCard.asGeneral
		case let .offDeviceMnemonic(offDeviceMnemonic, _):
			offDeviceMnemonic.asGeneral
		case let .password(password, _):
			password.asGeneral
		}
	}
}
