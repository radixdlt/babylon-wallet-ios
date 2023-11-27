import EngineToolkit

// MARK: - HDFactorSourceProtocol
// Empty marker protocol only
public protocol HDFactorSourceProtocol: BaseFactorSourceProtocol {
	var factorSourceID: FactorSourceID { get }
}

// MARK: - DeviceFactorSource + HDFactorSourceProtocol
extension DeviceFactorSource: HDFactorSourceProtocol {
	public var factorSourceID: FactorSourceID { id.embed() }
}

// MARK: - LedgerHardwareWalletFactorSource + HDFactorSourceProtocol
extension LedgerHardwareWalletFactorSource: HDFactorSourceProtocol {
	public var factorSourceID: FactorSourceID { id.embed() }
}

// MARK: - OffDeviceMnemonicFactorSource + HDFactorSourceProtocol
extension OffDeviceMnemonicFactorSource: HDFactorSourceProtocol {
	public var factorSourceID: FactorSourceID { id.embed() }
}
