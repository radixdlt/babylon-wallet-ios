import Foundation
import Sargon

// MARK: - HDFactorSourceProtocol
public protocol HDFactorSourceProtocol {
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
