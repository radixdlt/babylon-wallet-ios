import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - FactorInstance
/// An factor instance created from a FactorSource.
public struct FactorInstance: Sendable, Hashable, Codable, Identifiable {
	// FIXME: COMPLETELY incorrectly implemented, MUST be sent in probably, because Profile cannot
	// use EngineToolkit which we must, to do Blake hash.
	/// A string uniquely identifying this Factor Source, on format:
	/// `FactorSourceKind(1) || "#" || BadgeAddress(String)` e.g.
	/// `de#resource_sim1qgqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs64j5z6:[9f58abcbc2ebd2da349acb10773ffbc37b6af91fa8df2486c9ea]"`
	public struct ID: Sendable, Hashable, Codable {
		public let factorSourceKind: FactorSourceKind
		public let badgeAddress: BadgeAddress

		/// FIXME: Update to whatever is the exact correct representation which
		/// becomes clear once we start integrating with the network (/ledger/node/gateway)
		public enum BadgeAddress: Sendable, Hashable, Codable {
			/// "virtual"/"non fungible"
			case virtual(NonFungibleGlobalId)

			/// "physical"/"real"/"fungible"
			case resourceAddress(ResourceAddress)
		}
	}

	/// The ID of the `FactorSource` that was used to produce this
	/// factor instance. We will lookup the `FactorSource` in the
	/// `Profile` and can present user with instruction to re-access
	/// this factor source in order control the `badge`.
	public let factorSourceID: FactorSource.ID

	// FIXME: COMPLETELY incorrectly implemented, MUST be sent in probably, because Profile cannot
	// use EngineToolkit which we must, to do Blake hash.
	/// FactorInstanceID is a referenced by security structure
	public let id: ID

	/// Either a "physical" badge (NFT) or some source for recreation of a producer
	/// of a virtual badge (signature), e.g. a HD derivation path, from which a private key
	/// is derived which produces virtual badges (signatures).
	public let badge: Badge

	public init(
		factorSourceID: FactorSource.ID,
		badge: Badge
	) {
		self.factorSourceID = factorSourceID
		self.badge = badge

		// FIXME: COMPLETELY incorrectly implemented, MUST be sent in probably, because Profile cannot
		// use EngineToolkit which we must, to do Blake hash.
		self.id = {
			switch badge {
			case let .virtual(.hierarchicalDeterministic(hdPubKey)):
				switch hdPubKey.publicKey {
				case let .ecdsaSecp256k1(k1PubKey):
					// FIXME: THIS IS COMPLETELY WRONG, placeholder only
					let payload = k1PubKey.compressedRepresentation.prefix(26)
					return .init(
						factorSourceKind: factorSourceID.factorSourceKind,
						badgeAddress: .virtual(.init(
							resourceAddress: .init(
								// FIXME: This is wrong! should be fetched from gateway or from RET... and depends on the network.
								address: "resource_sim1qgqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq056vhf"
							),
							nonFungibleLocalId: .bytes(Array(payload))
						)
						)
					)
				case let .eddsaEd25519(curve25519PubKey):
					// FIXME: THIS IS COMPLETELY WRONG, placeholder only
					let payload = curve25519PubKey.compressedRepresentation.prefix(26)
					return .init(
						factorSourceKind: factorSourceID.factorSourceKind,
						badgeAddress: .virtual(.init(
							resourceAddress: .init(
								// FIXME: This is wrong! should be fetched from gateway or from RET... and depends on the network.
								address: "resource_sim1qgqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs64j5z6"
							),
							nonFungibleLocalId: .bytes(Array(payload))
						)
						)
					)
				}
			}
		}()
	}
}

// MARK: FactorInstance.Badge
extension FactorInstance {
	/// Either a "physical" badge (NFT) or some source for recreation of a producer
	/// of a virtual badge (signature), e.g. a HD derivation path, from which a private key
	/// is derived which produces virtual badges (signatures).
	public enum Badge: Sendable, Hashable, Codable {
		/// The **source** of a virtual hierarchical deterministic badge, contains a
		/// derivation path and public key, from which a private key is derived which
		/// produces virtual badges (signatures).
		///
		/// The `.device` `FactorSource` produces `FactorInstance`s with this kind if badge source.
		case virtual(VirtualSource)

		public enum VirtualSource: Sendable, Hashable, Codable {
			case hierarchicalDeterministic(HierarchicalDeterministicPublicKey)
		}

		/// A "physical" or "real" (as opposed to "virtual") badge is an On-Ledger resource
		/// e.g. an NFT.
		///
		/// The `.trustedEntity` `FactorSource` produces `FactorInstance`s with this kind if badge source.
		// case physical(ResourceAddress) // Will soon be added
	}
}

extension FactorInstance {
	/// Tries to unwrap this factor instance's badge as virtual hierarchical deterministic one.
	public func virtualHierarchicalDeterministic() throws -> HierarchicalDeterministicFactorInstance {
		try .init(factorInstance: self)
	}
}

extension FactorInstance.Badge {
	internal enum Discriminator: String, Sendable, Equatable, Codable {
		case virtual = "virtualSource"
	}

	public enum CodingKeys: String, CodingKey {
		case discriminator, virtualSource
	}

	internal var discriminator: Discriminator {
		switch self {
		case .virtual: return .virtual
		}
	}

	public func encode(to encoder: Encoder) throws {
		var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
		try keyedContainer.encode(discriminator, forKey: .discriminator)
		switch self {
		case let .virtual(virtual):
			try keyedContainer.encode(
				virtual,
				forKey: .virtualSource
			)
		}
	}

	public init(from decoder: Decoder) throws {
		let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try keyedContainer.decode(Discriminator.self, forKey: .discriminator)
		switch discriminator {
		case .virtual:
			self = try .virtual(
				keyedContainer.decode(
					VirtualSource.self,
					forKey: .virtualSource
				)
			)
		}
	}
}

extension FactorInstance.Badge.VirtualSource {
	internal enum Discriminator: String, Sendable, Equatable, Codable {
		case hierarchicalDeterministic = "hierarchicalDeterministicPublicKey"
	}

	public enum CodingKeys: String, CodingKey {
		case discriminator, hierarchicalDeterministicPublicKey
	}

	internal var discriminator: Discriminator {
		switch self {
		case .hierarchicalDeterministic: return .hierarchicalDeterministic
		}
	}

	public func encode(to encoder: Encoder) throws {
		var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
		try keyedContainer.encode(discriminator, forKey: .discriminator)
		switch self {
		case let .hierarchicalDeterministic(hierarchicalDeterministic):
			try keyedContainer.encode(
				hierarchicalDeterministic,
				forKey: .hierarchicalDeterministicPublicKey
			)
		}
	}

	public init(from decoder: Decoder) throws {
		let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try keyedContainer.decode(Discriminator.self, forKey: .discriminator)
		switch discriminator {
		case .hierarchicalDeterministic:
			self = try .hierarchicalDeterministic(
				keyedContainer.decode(
					HierarchicalDeterministicPublicKey.self,
					forKey: .hierarchicalDeterministicPublicKey
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
public struct HierarchicalDeterministicFactorInstance: Sendable, Hashable, Codable {
	public let factorSourceID: FactorSource.ID
	public let publicKey: SLIP10.PublicKey
	public let derivationPath: DerivationPath

	public var factorInstance: FactorInstance {
		.init(
			factorSourceID: factorSourceID,
			badge: .virtual(
				.hierarchicalDeterministic(.init(
					publicKey: publicKey,
					derivationPath: derivationPath
				))
			)
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
		guard case let .virtual(.hierarchicalDeterministic(badge)) = factorInstance.badge else {
			throw BadgeIsNotVirtualHierarchicalDeterministic()
		}
		self.init(
			factorSourceID: factorInstance.factorSourceID,
			publicKey: badge.publicKey,
			derivationPath: badge.derivationPath
		)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		self = try container.decode(FactorInstance.self).virtualHierarchicalDeterministic()
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(factorInstance)
	}
}

// MARK: - BadgeIsNotVirtualHierarchicalDeterministic
struct BadgeIsNotVirtualHierarchicalDeterministic: Swift.Error {}
