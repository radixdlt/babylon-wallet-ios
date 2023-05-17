import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - FactorInstance
/// An factor instance created from a FactorSource.
public struct FactorInstance: Sendable, Hashable, Codable {
	/// The ID of the `FactorSource` that was used to produce this
	/// factor instance. We will lookup the `FactorSource` in the
	/// `Profile` and can present user with instruction to re-access
	/// this factor source in order control the `badge`.
	public let factorSourceID: FactorSource.ID

	/// Either a "physical" badge (NFT) or some source for recreation of a producer
	/// of a virtual badge (signature), e.g. a HD derivation path, from which a private key
	/// is derived which produces virtual badges (signatures).
	public let badge: Badge

	/// Either a "physical" badge (NFT) or some source for recreation of a producer
	/// of a virtual badge (signature), e.g. a HD derivation path, from which a private key
	/// is derived which produces virtual badges (signatures).
	public enum Badge: Sendable, Hashable, Codable {
		/// The **source** of a virtual hierarchical deterministic badge, contains a
		/// derivation path and public key, from which a private key is derived which
		/// produces virtual badges (signatures).
		///
		/// The `.device` `FactorSource` produces `FactorInstance`s with this kind if badge source.
		case virtualHierarchicalDeterministic(HierarchicalDeterministicPublicKey)

		/// A "physical" or "real" (as opposed to "virtual") badge is an On-Ledger resource
		/// e.g. an NFT.
		///
		/// The `.trustedEntity` `FactorSource` produces `FactorInstance`s with this kind if badge source.
		// case physical(ResourceAddress) // Will soon be added
	}

	/// Tries to unwrap this factor instance's badge as virtual hierarchical deterministic one.
	public func virtualHierarchicalDeterministic() throws -> HierarchicalDeterministicFactorInstance {
		try .init(factorInstance: self)
	}
}

extension FactorInstance.Badge {
	internal enum Discriminator: String, Sendable, Equatable, Codable {
		case virtualHierarchicalDeterministic
	}

	public enum CodingKeys: String, CodingKey {
		case discriminator, virtualHierarchicalDeterministicPublicKey
	}

	internal var discriminator: Discriminator {
		switch self {
		case .virtualHierarchicalDeterministic: return .virtualHierarchicalDeterministic
		}
	}

	public func encode(to encoder: Encoder) throws {
		var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
		try keyedContainer.encode(discriminator, forKey: .discriminator)
		switch self {
		case let .virtualHierarchicalDeterministic(virtualHierarchicalDeterministicPublicKey):
			try keyedContainer.encode(
				virtualHierarchicalDeterministicPublicKey,
				forKey: .virtualHierarchicalDeterministicPublicKey
			)
		}
	}

	public init(from decoder: Decoder) throws {
		let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try keyedContainer.decode(Discriminator.self, forKey: .discriminator)
		switch discriminator {
		case .virtualHierarchicalDeterministic:
			self = try .virtualHierarchicalDeterministic(
				keyedContainer.decode(
					HierarchicalDeterministicPublicKey.self,
					forKey: .virtualHierarchicalDeterministicPublicKey
				)
			)
		}
	}
}

// MARK: - HierarchicalDeterministicPublicKey
/// The **source** of a virtual hierarchical deterministic badge, contains a
/// derivation path and public key, from which a private key is derived which
/// produces virtual badges (signatures).
///
/// The `.device` `FactorSource` produces `FactorInstance`s with this kind if badge source.
public struct HierarchicalDeterministicPublicKey: Sendable, Hashable, Codable {
	/// The expected public key of the private key derived at `derivationPath`
	public let publicKey: SLIP10.PublicKey

	/// The HD derivation path for the key pair which produces virtual badges (signatures).
	public let derivationPath: DerivationPath

	public init(
		publicKey: SLIP10.PublicKey,
		derivationPath: DerivationPath
	) {
		self.publicKey = publicKey
		self.derivationPath = derivationPath
	}
}

// MARK: - HierarchicalDeterministicFactorInstance
/// A virtual hierarchical deterministic `FactorInstance`
public struct HierarchicalDeterministicFactorInstance: Sendable, Hashable {
	public let factorSourceID: FactorSource.ID
	public let publicKey: SLIP10.PublicKey
	public let derivationPath: DerivationPath

	public var factorInstance: FactorInstance {
		.init(
			factorSourceID: factorSourceID,
			badge: .virtualHierarchicalDeterministic(.init(
				publicKey: publicKey,
				derivationPath: derivationPath
			))
		)
	}

	public init(
		factorSourceID: FactorSource.ID,
		publicKey: SLIP10.PublicKey,
		derivationPath: DerivationPath
	) {
		self.factorSourceID = factorSourceID
		self.publicKey = publicKey
		self.derivationPath = derivationPath
	}

	public init(factorInstance: FactorInstance) throws {
		guard case let .virtualHierarchicalDeterministic(badge) = factorInstance.badge else {
			throw BadgeIsNotVirtualHierarchicalDeterministic()
		}
		self.init(
			factorSourceID: factorInstance.factorSourceID,
			publicKey: badge.publicKey,
			derivationPath: badge.derivationPath
		)
	}
}

// MARK: - BadgeIsNotVirtualHierarchicalDeterministic
struct BadgeIsNotVirtualHierarchicalDeterministic: Swift.Error {}
