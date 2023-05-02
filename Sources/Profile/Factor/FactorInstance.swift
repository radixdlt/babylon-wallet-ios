import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - FactorInstance
public struct FactorInstance: Sendable, Hashable, Codable {
	/// The ID of the `FactorSource` that was used to produce this
	/// factor instance. We will lookup the `FactorSource` in the
	/// `Profile` and can present user with instruction to re-access
	/// this factor source in order to re-produce the Private key
	/// of this FactorInstance.
	///
	/// In case of Non-HD the factor source will be
	/// very similar to this instance.
	public let factorSourceID: FactorSource.ID

	/// Also contains info about which Curve
	public let publicKey: SLIP10.PublicKey

	/// Optional, since it might be a single factor instance, not derived from
	/// and HD factor source
	public let derivationPath: DerivationPath?

	public init(
		factorSourceID: FactorSource.ID,
		publicKey: SLIP10.PublicKey,
		derivationPath: DerivationPath?
	) {
		self.factorSourceID = factorSourceID
		self.publicKey = publicKey
		self.derivationPath = derivationPath
	}
}

// MARK: - Signature
public struct Signature: Sendable, Hashable {
	public let signatureWithPublicKey: SignatureWithPublicKey
	public let derivationPath: DerivationPath?
	public init(
		signatureWithPublicKey: SignatureWithPublicKey,
		derivationPath: DerivationPath?
	) {
		self.signatureWithPublicKey = signatureWithPublicKey
		self.derivationPath = derivationPath
	}
}

// MARK: - SignatureOf
public struct SignatureOf<Entity: EntityProtocol & Hashable>: Sendable, Hashable {
	public let entity: Entity
	public let factorInstance: FactorInstance
	public let signature: Signature

	public init(
		entity: Entity,
		factorInstance: FactorInstance,
		signature: Signature
	) throws {
		guard factorInstance.derivationPath == signature.derivationPath else {
			throw Error.derivationPathDiscrepancy
		}
		guard factorInstance.publicKey == signature.signatureWithPublicKey.publicKey else {
			throw Error.publicKeyDiscrepancy
		}
		self.entity = entity
		self.factorInstance = factorInstance
		self.signature = signature
	}

	enum Error: Swift.Error {
		case derivationPathDiscrepancy
		case publicKeyDiscrepancy
	}
}

public typealias AccountSignature = SignatureOf<Profile.Network.Account>
public typealias PersonaSignature = SignatureOf<Profile.Network.Persona>
