import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - FactorInstance
/// An factor instance created from a **hierarchical deterministic** FactorSource.
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

	/// The derivation path used to derive the publicKey.
	public let derivationPath: DerivationPath

	public init(
		factorSourceID: FactorSource.ID,
		publicKey: SLIP10.PublicKey,
		derivationPath: DerivationPath
	) {
		self.factorSourceID = factorSourceID
		self.publicKey = publicKey
		self.derivationPath = derivationPath
	}
}

// MARK: - SignatureOfEntity
public struct SignatureOfEntity: Sendable, Hashable {
	public let signerEntity: EntityPotentiallyVirtual
	public let derivationPath: DerivationPath
	public let factorSourceID: FactorSourceID
	public let signatureWithPublicKey: SignatureWithPublicKey

	public init(
		signerEntity: EntityPotentiallyVirtual,
		derivationPath: DerivationPath,
		factorSourceID: FactorSourceID,
		signatureWithPublicKey: SignatureWithPublicKey
	) {
		self.signerEntity = signerEntity
		self.derivationPath = derivationPath
		self.factorSourceID = factorSourceID
		self.signatureWithPublicKey = signatureWithPublicKey
	}
}
