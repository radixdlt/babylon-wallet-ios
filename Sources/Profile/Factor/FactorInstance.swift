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
