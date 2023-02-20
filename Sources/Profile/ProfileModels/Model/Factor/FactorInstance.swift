import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - FactorInstance

/// If we also need to store authenticationKey, can be implemented like this:
///
///     public struct FactorInstance: Sendable, Hashable, Codable {
///          public let factorSourceID: FactorSource.ID
///
///          public struct Key: Sendable, Hashable, Codable {
///              public enum Kind: String, Sendable, Hashable, Codable {
///                  case authentication
///                  case transaction
///              }
///
///              /// If this key is used for authentication or for transaction signing.
///              public let kind: Kind
///
///              /// Also contains info about which Curve
///              public let publicKey: Engine.PublicKey
///
///              /// Optional, since it might be a single factor instance, not derived from
///              /// and HD factor source
///              public let derivationPath: DerivationPath?
///          }
///
///          /// Public key and possible derivation path of the key used to sign transactions
///          public let transactionKey: Key
///
///          /// Public key and possible derivation path of the key used for authentication.
///          /// This is typically `nil` for `FactorInstance`s from FactorSource's which kind
///          /// is `trustedContact` or `trustedEnterprise`
///          public let authenticationKey: Key?
///
///          public init(
///              factorSourceID: FactorSource.ID,
///              transactionKey: Key,
///              authenticationKey: Key?
///          ) {
///              precondition(transactionKey.kind == .transaction)
///              if let authenticationKey {
///                  precondition(authenticationKey.kind == .authentication)
///              }
///              self.factorSourceID = factorSourceID
///              self.authenticationKey = authenticationKey
///              self.transactionKey = transactionKey
///          }
///      }
///
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
	public let publicKey: Engine.PublicKey

	/// Optional, since it might be a single factor instance, not derived from
	/// and HD factor source
	public let derivationPath: DerivationPath?

	public init(
		factorSourceID: FactorSource.ID,
		publicKey: Engine.PublicKey,
		derivationPath: DerivationPath?
	) {
		self.factorSourceID = factorSourceID
		self.publicKey = publicKey
		self.derivationPath = derivationPath
	}
}
