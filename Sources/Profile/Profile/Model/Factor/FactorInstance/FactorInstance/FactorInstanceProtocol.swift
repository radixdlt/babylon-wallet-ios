import Bite
import Foundation
import Tagged

/// An identifier for some factor identifier, it **MUST** be a a stable and unique identifer.
public typealias FactorInstanceID = Tagged<FactorInstance, HexCodable>

// MARK: - FactorInstanceProtocol
/// A factor instance of some factor source.
public protocol FactorInstanceProtocol {
	/// The kind of factor instance this is.
	static var factorInstanceKind: FactorInstanceKind { get }

	/// Most commonly this is `SHA256(SHA256(publicKey.compressedForm)`. For `TrustedContactFactorInstance` it might be something else.
	var factorInstanceID: FactorInstanceID { get }

	/// Reference to the factor **source** used to create this factor instance.
	var factorSourceReference: FactorSourceReference { get }

	/// When this factor instance was created.
	var initializationDate: Date { get }

	/// Wraps this specific type of factor instance to the shared
	/// nominal type `FactorInstance` (enum)
	func wrapAsFactorInstance() -> FactorInstance

	/// Tries to unwraps the nominal type `FactorInstance` (enum)
	/// into this specific type.
	static func unwrap(factorInstance: FactorInstance) -> Self?
}

public extension FactorInstanceProtocol {
	var factorInstanceKind: FactorInstanceKind {
		Self.factorInstanceKind
	}
}

public extension FactorInstanceProtocol where Self: Identifiable, Self.ID == FactorInstanceID {
	var id: ID { factorInstanceID }
}
