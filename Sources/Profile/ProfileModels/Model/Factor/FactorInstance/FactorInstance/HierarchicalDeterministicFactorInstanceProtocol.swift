import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - SLIP10CurveSpecifierProtocol
/// A type which uses some SLIP10 compatible Elliptic Curve for cryptographic operations.
public protocol SLIP10CurveSpecifierProtocol {
	/// The elliptic curve compatible with SLIP-10 used during derivation.
	associatedtype Curve: Slip10SupportedECCurve
}

// MARK: - FactorInstanceHierarchicalDeterministicProtocol
/// A Hierarchical Deterministic factor instance of some Hierarchical Deterministic factor source,
/// derived using the `derivationPath`, which produced the `publicKey`.
public protocol FactorInstanceHierarchicalDeterministicProtocol: FactorInstanceProtocol {
	/// The public key derived.
	var publicKey: SLIP10.PublicKey { get }
	///  The derivation path used to derive the `publicKey`.
	var derivationPath: DerivationPath { get }
}

// MARK: - FactorInstanceHierarchicalDeterministicSLIP10Protocol
/// A Hierarchical Deterministic factor instance of some Hierarchical Deterministic factor source,
/// derived using a `SLIP-10` compatible Elliptic Curve using the `derivationPath`, which produced the
/// `publicKey`.
public protocol FactorInstanceHierarchicalDeterministicSLIP10Protocol: FactorInstanceHierarchicalDeterministicProtocol, SLIP10CurveSpecifierProtocol {
	init(
		factorSourceReference: FactorSourceReference,
		publicKey: SLIP10.PublicKey,
		derivationPath: DerivationPath,
		initializationDate: Date
	)
}

// MARK: - FactorInstanceNonHardwareProtocol
/// A protocol all **Non-Hardware** FactorInstances conform to.
public protocol FactorInstanceNonHardwareProtocol: FactorInstanceProtocol {}

// MARK: - FactorInstanceNonHardwareHierarchicalDeterministicProtocol
/// A protocol all **Non-Hardware** Hierarchical Deterministic FactorInstances conform to.
public protocol FactorInstanceNonHardwareHierarchicalDeterministicProtocol: FactorInstanceHierarchicalDeterministicProtocol, FactorInstanceNonHardwareProtocol {}

// MARK: - FactorInstanceHardwareProtocol
/// A protocol all **Hardware** FactorInstances conform to.
public protocol FactorInstanceHardwareProtocol: FactorInstanceProtocol {}

// MARK: - FactorInstanceHardwareHierarchicalDeterministicProtocol
/// A protocol all **Hardware** Hierarchical Deterministic FactorInstances conform to.
public protocol FactorInstanceHardwareHierarchicalDeterministicProtocol: FactorInstanceHierarchicalDeterministicProtocol, FactorInstanceHardwareProtocol {}
