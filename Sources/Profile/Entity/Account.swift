import Cryptography
import EngineToolkit
import EngineToolkitModels
import Prelude

// MARK: - OnNetwork.Account
extension OnNetwork {
	/// A network unique account with a unique public address and a set of cryptographic
	/// factors used to control it. The account is either `virtual` or not. By "virtual"
	/// we mean that the Radix Public Ledger does not yet know of the public address
	/// of this account.
	public struct Account:
		EntityProtocol,
		Sendable,
		Hashable,
		Codable,
		Identifiable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		/// The ID of the network this account exists on.
		public let networkID: NetworkID

		/// The globally unique and identifiable Radix component address of this account. Can be used as
		/// a stable ID. Cryptographically derived from a seeding public key which typically was created by
		/// the `DeviceFactorSource` (and typically the same public key as an instance of the device factor
		/// typically used in the primary role of this account).
		public let address: EntityAddress

		/// Security of this account
		public var securityState: EntitySecurityState

		/// An indentifier for the gradient for this account, to be displayed in wallet
		/// and possibly by dApps.
		public let appearanceID: AppearanceID

		/// A required non empty display name, used by presentation layer and sent to Dapps when requested.
		public let displayName: NonEmpty<String>

		public init(
			networkID: NetworkID,
			address: EntityAddress,
			securityState: EntitySecurityState,
			appearanceID: AppearanceID,
			displayName: NonEmpty<String>
		) {
			self.networkID = networkID
			self.address = address
			self.securityState = securityState
			self.appearanceID = appearanceID
			self.displayName = displayName
		}
	}
}

extension OnNetwork.Account {
	public static func deriveAddress(
		networkID: NetworkID,
		publicKey: SLIP10.PublicKey
	) throws -> EntityAddress {
		let response = try EngineToolkit().deriveVirtualAccountAddressRequest(
			request: .init(
				publicKey: publicKey.intoEngine(),
				networkId: networkID
			)
		).get()

		return try EntityAddress(address: response.virtualAccountAddress.address)
	}
}

extension OnNetwork.Account {
	public static var entityKind: EntityKind { .account }

	public typealias EntityAddress = AccountAddress

	/// A stable and globally unique identifier of an account.
	public typealias ID = EntityAddress

	/// A stable and globally unique identifier for this account.
	public var id: ID { address }
}

extension OnNetwork.Account {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"displayName": String(describing: displayName),
				"address": address,
				"securityState": securityState,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		"displayName": \(String(describing: displayName)),
		"address": \(address),
		"securityState": \(securityState)
		"""
	}
}
