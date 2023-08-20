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
			self.address = address
			self.securityState = securityState
			self.appearanceID = extraProperties.appearanceID
			self.onLedgerSettings = .default
			self.displayName = displayName
		}
	}
}

// MARK: - Profile.Network.Account.OnLedgerSettings
extension Profile.Network.Account {
	public struct OnLedgerSettings: Hashable, Sendable, Codable {
		/// Controls the ability of third-parties to deposit into this account
		public var thirdPartyDeposits: ThirdPartyDeposits

		public init(thirdPartyDeposits: ThirdPartyDeposits) {
			self.thirdPartyDeposits = thirdPartyDeposits
		}

		/// The default value for newly created accounts.
		/// After the account is created the OnLedgerSettings will be updated either by User or by syncing with the Ledger.
		public static let `default` = Self(thirdPartyDeposits: .default)
	}
}

// MARK: - Profile.Network.Account.OnLedgerSettings.ThirdPartyDeposits
extension Profile.Network.Account.OnLedgerSettings {
	public struct ThirdPartyDeposits: Hashable, Sendable, Codable {
		/// The general deposit rule to apply
		public enum DepositRule: Hashable, Sendable, Codable {
			case acceptAll
			case acceptKnown
			case denyAll
		}

		/// The addresses that can be added as exception to the `DepositRule`
		public enum DepositAddress: Hashable, Sendable, Codable {
			case resourceAddress(ResourceAddress)
			case nonFungibleGlobalID(NonFungibleGlobalId)
		}

		/// The exception kind for deposit address
		public enum DepositAddressExceptionRule: Hashable, Sendable, Codable {
			/// A resource can always be deposited in to the account by third-parties
			case allow
			/// A resource can never be deposited in to the account by third-parties
			case deny
		}

		/// Controls the ability of thir-parties to deposit into this account
		public var depositRule: DepositRule

		/// Denies or allows third-party deposits of specific assets by ignoring the `depositMode`
		public var assetsExceptionList: OrderedDictionary<DepositAddress, DepositAddressExceptionRule>

		/// Allows certain third-party depositors to deposit assets freely.
		/// Note: There is no `deny` counterpart for this.
		public var depositorsAllowList: OrderedSet<DepositAddress>

		public init(
			depositRule: DepositRule,
			assetsExceptionList: OrderedDictionary<DepositAddress, DepositAddressExceptionRule>,
			depositorsAllowList: OrderedSet<DepositAddress>
		) {
			self.depositRule = depositRule
			self.assetsExceptionList = assetsExceptionList
			self.depositorsAllowList = depositorsAllowList
		}

		/// On Ledger default is `acceptAll` for deposit mode and empty lists
		public static let `default` = Self(depositRule: .acceptAll, assetsExceptionList: [:], depositorsAllowList: [])
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

extension Profile.Network.Account.OnLedgerSettings.ThirdPartyDeposits.DepositAddress {
	private enum CodingKeys: String, CodingKey {
		case resourceAddress
		case nonFungibleGlobalID
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		if var resourceAddressContainer = try? container.nestedUnkeyedContainer(forKey: .resourceAddress) {
			self = try .resourceAddress(.init(validatingAddress: resourceAddressContainer.decode(String.self)))
		} else if var nftGlobalIDContainer = try? container.nestedUnkeyedContainer(forKey: .nonFungibleGlobalID) {
			self = try .nonFungibleGlobalID(.init(nonFungibleGlobalId: nftGlobalIDContainer.decode(String.self)))
		} else {
			throw DecodingError.dataCorruptedError(forKey: .resourceAddress, in: container, debugDescription: "Invalid Badge Address")
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case let .resourceAddress(address):
			var nestedContainer = container.nestedUnkeyedContainer(forKey: .resourceAddress)
			try nestedContainer.encode(address.address)

		case let .nonFungibleGlobalID(id):
			var nestedContainer = container.nestedUnkeyedContainer(forKey: .nonFungibleGlobalID)
			try nestedContainer.encode(id.asStr())
		}
	}
}
