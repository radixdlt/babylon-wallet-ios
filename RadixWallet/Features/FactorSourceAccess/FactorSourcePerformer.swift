import Foundation

// MARK: - FactorSourcePerformer
/// An enum containing the necessary information to use a given `FactorSource`.
///
/// This becomes handy to unify factor sources that can be used directly (`device`, `ledger` & `arculusCard`) and those
/// that require user input to retrieve the associated `MnemonicWithPassphrase` (`offDeviceMnemonic` & `password`).
enum FactorSourcePerformer: Sendable, Hashable {
	case device(DeviceFactorSource)
	case ledger(LedgerHardwareWalletFactorSource)
	case arculusCard(ArculusCardFactorSource)
	case offDeviceMnemonic(OffDeviceMnemonicFactorSource, MnemonicWithPassphrase)
	case password(PasswordFactorSource, MnemonicWithPassphrase)
}

extension FactorSourcePerformer {
	var factorSource: FactorSource {
		switch self {
		case let .device(device):
			device.asGeneral
		case let .ledger(ledger):
			ledger.asGeneral
		case let .arculusCard(arculusCard):
			arculusCard.asGeneral
		case let .offDeviceMnemonic(offDeviceMnemonic, _):
			offDeviceMnemonic.asGeneral
		case let .password(password, _):
			password.asGeneral
		}
	}
}
