import EngineToolkit
import Foundation
import SLIP10

// MARK: - FactorSourceProtocol
/// A protocol **all** FactorSources conform to.
public protocol FactorSourceProtocol {
	/// Type specific type of FactorInstance this source can produce.
	associatedtype Instance: FactorInstanceProtocol

	associatedtype CreateFactorInstanceInput: CreateFactorInstanceInputProtocol

	/// The kind of factor source this is.
	static var factorSourceKind: FactorSourceKind { get }

	/// When this factor source was added by the user to the wallet.
	var creationDate: Date { get }

	/// A stable and globally unique identifier for this factor source.
	var factorSourceID: FactorSourceID { get }

	/// Creation of a `FactorInstance` using this factor and external `input`.
	func createInstance(input: CreateFactorInstanceInput) async throws -> CreateFactorInstanceWithKey<Instance>

	/// Wraps this specific type of factor source to the shared
	/// nominal type `FactorSource` (enum)
	func wrapAsFactorSource() -> FactorSource

	/// Tries to unwraps the nominal type `FactorSource` (enum)
	/// into this specific type.
	static func unwrap(factorSource: FactorSource) -> Self?
}

public extension FactorSourceProtocol where Self: Identifiable, Self.ID == FactorSourceID {
	var id: ID { factorSourceID }
}

public extension FactorSourceProtocol {
	var factorSourceKind: FactorSourceKind { Self.factorSourceKind }
	var reference: FactorSourceReference {
		.init(factorSourceKind: Self.factorSourceKind, factorSourceID: factorSourceID)
	}
}

// MARK: - FactorSourceHierarchicalDeterministicProtocol
/// A protocol all **Hierarchical Deterministic** FactorSources conform to.
public protocol FactorSourceHierarchicalDeterministicProtocol: FactorSourceProtocol
	where
	Instance: FactorInstanceHierarchicalDeterministicProtocol,
	CreateFactorInstanceInput: CreateHierarchicalDeterministicFactorInstanceInputProtocol
{}

// MARK: - FactorSourceNonHardwareProtocol
/// A protocol all **Non-Hardware** FactorSources conform to.
public protocol FactorSourceNonHardwareProtocol: FactorSourceProtocol
	where
	Instance: FactorInstanceNonHardwareProtocol
{}

// MARK: - FactorSourceHardwareProtocol
/// A protocol all **Hardware** FactorSources conform to.
public protocol FactorSourceHardwareProtocol: FactorSourceProtocol
	where
	Instance: FactorInstanceHardwareProtocol
{}

// MARK: - SLIP10FactorSourceHierarchicalDeterministicProtocol
/// A protocol for SLIP10 Compatible **Hierarchical Deterministic**  Factor Sources.
public protocol SLIP10FactorSourceHierarchicalDeterministicProtocol:
	SLIP10CurveSpecifierProtocol,
	FactorSourceHierarchicalDeterministicProtocol
	where
	Instance: FactorInstanceHierarchicalDeterministicSLIP10Protocol,
	Instance.Curve == Self.Curve
{
	static func embedPublicKey(_ publicKey: Self.Curve.PublicKey) -> PublicKey
	static func embedPrivateKey(_ privateKey: Self.Curve.PrivateKey) -> PrivateKey
}

// MARK: - FactorSourceNonHardwareHierarchicalDeterministicProtocol
/// A protocol all **Non-Hardware** Hierarchical Deterministic FactorSources conform to.
public protocol FactorSourceNonHardwareHierarchicalDeterministicProtocol: FactorSourceHierarchicalDeterministicProtocol, FactorSourceNonHardwareProtocol
	where
	Instance: FactorInstanceNonHardwareHierarchicalDeterministicProtocol,
	CreateFactorInstanceInput: CreateHierarchicalDeterministicFactorInstanceInputProtocol
{}

// MARK: - FactorSourceHardwareHierarchicalDeterministicProtocol
/// A protocol all **Hardware** Hierarchical Deterministic FactorSources conform to.
public protocol FactorSourceHardwareHierarchicalDeterministicProtocol: FactorSourceHierarchicalDeterministicProtocol, FactorSourceHardwareProtocol
	where
	Instance: FactorInstanceHardwareHierarchicalDeterministicProtocol,
	CreateFactorInstanceInput: CreateHierarchicalDeterministicFactorInstanceInputProtocol
{}

// MARK: - CreateFactorInstanceInputProtocol
/// Input for creation of factor instances
public protocol CreateFactorInstanceInputProtocol {}

// MARK: - CreateHierarchicalDeterministicFactorInstanceInputProtocol
/// Input needed to create a Hierarchical Deterministic Factor Instance
public protocol CreateHierarchicalDeterministicFactorInstanceInputProtocol: CreateFactorInstanceInputProtocol {
	var derivationPath: DerivationPath { get }
}
