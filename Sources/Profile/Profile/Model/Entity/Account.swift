import CustomDump
import Foundation

// MARK: - OnNetwork.Account
public extension OnNetwork {
	/// A network unique account with a unique public address and a set of cryptographic
	/// factors used to control it. The account is either `virtual` or not. By "virtual"
	/// we mean that the Radix Public Ledger does not yet know of the public address
	/// of this account.
	struct Account:
		EntityProtocol,
		Sendable,
		Hashable,
		Codable,
		Identifiable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		/// The globally unique and identifiable Radix component address of this account. Can be used as
		/// a stable ID. Cryptographically derived from a seeding public key which typically was created by
		/// the `DeviceFactorSource` (and typically the same public key as an instance of the device factor
		/// typically used in the primary role of this account).
		public let address: EntityAddress

		/// Security of this account
		public var securityState: EntitySecurityState

		/// The index of this account, in the list of accounts for a certain network. This means that
		/// profile on network `mainnet` will have an account with `accountIndex = 0`, but so can an
		/// account on network `testnet` too! However, their `address`es will differ!
		public let index: Index

		/// An indentifier for the gradient for this account, to be displayed in wallet
		/// and possibly by dApps.
		public let appearanceID: AppearanceID

		/// The SLIP10 compatible Hierarchical Deterministic derivation path which is used to derive
		/// the public keys of the factors of the different roles, if the factor source kind of said factor
		/// instance supports Hierarchical Deterministic derivation.
		public let derivationPath: EntityDerivationPath

		/// An optional displayName or label, used by presentation layer only.
		public let displayName: String?

		public init(
			address: EntityAddress,
			securityState: EntitySecurityState,
			index: Index,
			appearanceID: AppearanceID? = nil,
			derivationPath: EntityDerivationPath,
			displayName: String?
		) {
			self.address = address
			self.securityState = securityState
			self.index = index
			self.appearanceID = appearanceID ?? AppearanceID.fromIndex(index)
			self.derivationPath = derivationPath
			self.displayName = displayName
		}
	}
}

public extension OnNetwork.Account {
	static var entityKind: EntityKind { .account }

	typealias EntityAddress = AccountAddress

	/// Index in list of collection of accounts, per network.
	typealias Index = Int

	/// A stable and globally unique identifier of an account.
	typealias ID = EntityAddress

	typealias EntityDerivationPath = AccountHierarchicalDeterministicDerivationPath

	/// A stable and globally unique identifier for this account.
	var id: ID { address }
}

public extension OnNetwork.Account {
	var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"displayName": String(describing: displayName),
				"index": index,
				"address": address,
				"securityState": securityState,
				"derivationPath": derivationPath,
			],
			displayStyle: .struct
		)
	}

	var description: String {
		"""
		"displayName": \(String(describing: displayName)),
		"index": \(index),
		"address": \(address),
		"securityState": \(securityState),
		"derivationPath": \(derivationPath)
		"""
	}
}
