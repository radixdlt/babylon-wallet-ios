import EngineToolkitModels
import Prelude

// MARK: - HDFactorSourceProtocol
public protocol HDFactorSourceProtocol: BaseFactorSourceProtocol {
	var nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork? { get }
}

// MARK: - DeviceFactorSource + HDFactorSourceProtocol
extension DeviceFactorSource: HDFactorSourceProtocol {}

// MARK: - LedgerHardwareWalletFactorSource + HDFactorSourceProtocol
extension LedgerHardwareWalletFactorSource: HDFactorSourceProtocol {}

// MARK: - OffDeviceMnemonicFactorSource + HDFactorSourceProtocol
extension OffDeviceMnemonicFactorSource: HDFactorSourceProtocol {
	public var nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork? {
		nil
	}
}
