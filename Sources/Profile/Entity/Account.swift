import Cryptography
import EngineKit
import Prelude

// MARK: - EntityExtraProperties
public enum EntityExtraProperties {
	case forAccount(Profile.Network.Account.ExtraProperties)
	case forPersona(Profile.Network.Persona.ExtraProperties)
}

extension EntityExtraProperties {
	struct WrongEntityType: Swift.Error {}

	public func get<Entity: EntityProtocol>(
		entityType: Entity.Type
	) throws -> Entity.ExtraProperties {
		switch self {
		case let .forAccount(extraProperties):
			guard let typed = extraProperties as? Entity.ExtraProperties else {
				throw WrongEntityType()
			}
			return typed
		case let .forPersona(extraProperties):
			guard let typed = extraProperties as? Entity.ExtraProperties else {
				throw WrongEntityType()
			}
			return typed
		}
	}
}

// MARK: - Profile.Network.Account
extension Profile.Network {
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

		public var index: HD.Path.Component.Child.Value {
			securityState.entityIndex
		}

		/// The globally unique and identifiable Radix component address of this account. Can be used as
		/// a stable ID. Cryptographically derived from a seeding public key which typically was created by
		/// the `DeviceFactorSource` (and typically the same public key as an instance of the device factor
		/// typically used in the primary role of this account).
		public let address: EntityAddress

		/// Security of this account
		public var securityState: EntitySecurityState

		/// An indentifier for the gradient for this account, to be displayed in wallet
		/// and possibly by dApps.
		public var appearanceID: AppearanceID

		/// A required non empty display name, used by presentation layer and sent to Dapps when requested.
		public var displayName: NonEmpty<String>

		/// The on ledger synced settings for this account
		public var onLedgerSettings: OnLedgerSettings

		public init(
			networkID: NetworkID,
			address: EntityAddress,
			securityState: EntitySecurityState,
			displayName: NonEmpty<String>,
			extraProperties: ExtraProperties
		) {
			self.networkID = networkID
			self.address = try! .init(validatingAddress: "account_tdx_2_12x2lz8ga95twa6wgfwhwkq6q790djw9gq6v069gukgh2y7q4denar2")
			self.securityState = securityState
			self.appearanceID = extraProperties.appearanceID
			self.onLedgerSettings = .default
			self.displayName = displayName
		}
	}
}

extension Profile.Network.Account {
	/// Ephemeral, only used as arg passed to init.
	public struct ExtraProperties: Sendable {
		public var appearanceID: AppearanceID

		public init(appearanceID: AppearanceID) {
			self.appearanceID = appearanceID
		}

		public init(numberOfAccountsOnNetwork: Int) {
			self.init(appearanceID: .fromIndex(numberOfAccountsOnNetwork))
		}
	}

	public init(
		networkID: NetworkID,
		address: EntityAddress,
		securityState: EntitySecurityState,
		appearanceID: AppearanceID,
		displayName: NonEmpty<String>
	) {
		self.init(
			networkID: networkID,
			address: address,
			securityState: securityState,
			displayName: displayName,
			extraProperties: .init(appearanceID: appearanceID)
		)
	}

	public static let nameMaxLength = 30

	public static func deriveVirtualAddress(
		networkID: NetworkID,
		factorInstance: HierarchicalDeterministicFactorInstance
	) throws -> EntityAddress {
		_ = try factorInstance.derivationPath.asAccountPath()
		let engineAddress = try deriveVirtualAccountAddressFromPublicKey(publicKey: factorInstance.publicKey.intoEngine(), networkId: networkID.rawValue)
		return AccountAddress(address: engineAddress.addressString(), decodedKind: engineAddress.entityType())
	}

	public var isOlympiaAccount: Bool {
		// Not the cleanest way, but it is guaranteed to be deterministic
		switch self.securityState {
		case let .unsecured(control):
			if case .ecdsaSecp256k1 = control.transactionSigning.publicKey {
				return true
			}
		}
		return false
	}

	public var isLedgerAccount: Bool {
		switch self.securityState {
		case let .unsecured(control):
			return control.transactionSigning.factorSourceID.kind == .ledgerHQHardwareWallet
		}
	}
}

// MARK: - WrongEntityInDerivationPath
struct WrongEntityInDerivationPath: Swift.Error {}

// MARK: - NoDerivationPath
struct NoDerivationPath: Error {}

extension Profile.Network.Account {
	public static var entityKind: EntityKind { .account }

	public typealias EntityAddress = AccountAddress
}

extension Profile.Network.Account {
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
