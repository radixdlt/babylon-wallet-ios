import Foundation
import Sargon

// MARK: - HDFactorSourceProtocol
/// Just a marker protocol for factor sources which are Hierarchical deterministic
public protocol HDFactorSourceProtocol: BaseFactorSourceProtocol {}

// MARK: - DeviceFactorSource + HDFactorSourceProtocol
extension DeviceFactorSource: HDFactorSourceProtocol {}

// MARK: - LedgerHardwareWalletFactorSource + HDFactorSourceProtocol
extension LedgerHardwareWalletFactorSource: HDFactorSourceProtocol {}
