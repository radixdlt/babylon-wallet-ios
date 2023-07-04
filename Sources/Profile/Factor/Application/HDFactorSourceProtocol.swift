import EngineToolkitModels
import Prelude

// MARK: - HDFactorSourceProtocol
// Empty marker protocol only
public protocol HDFactorSourceProtocol: BaseFactorSourceProtocol {}

// MARK: - DeviceFactorSource + HDFactorSourceProtocol
extension DeviceFactorSource: HDFactorSourceProtocol {}

// MARK: - LedgerHardwareWalletFactorSource + HDFactorSourceProtocol
extension LedgerHardwareWalletFactorSource: HDFactorSourceProtocol {}

// MARK: - OffDeviceMnemonicFactorSource + HDFactorSourceProtocol
extension OffDeviceMnemonicFactorSource: HDFactorSourceProtocol {}
