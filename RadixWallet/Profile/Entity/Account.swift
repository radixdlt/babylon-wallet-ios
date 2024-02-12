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

		/// Flags that are currently set on entity.
		@DefaultCodable.EmptyCollection
		public var flags: Flags

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
			self.displayName = displayName
			self.flags = []
			self.appearanceID = extraProperties.appearanceID
			self.onLedgerSettings = extraProperties.onLedgerSettings
		}
	}
}

extension Profile.Network.Account {
	/// Ephemeral, only used as arg passed to init.
	public struct ExtraProperties: Sendable {
		public var appearanceID: AppearanceID
		public let onLedgerSettings: OnLedgerSettings

		public init(
			appearanceID: AppearanceID,
			onLedgerSettings: OnLedgerSettings = .default
		) {
			self.appearanceID = appearanceID
			self.onLedgerSettings = onLedgerSettings
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
		try deriveVirtualAccountAddressFromPublicKey(
			publicKey: factorInstance.publicKey.intoEngine(),
			networkId: networkID.rawValue
		)
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
			control.transactionSigning.factorSourceID.kind == .ledgerHQHardwareWallet
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
				"flags": flags,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		"displayName": \(String(describing: displayName)),
		"address": \(address),
		"securityState": \(securityState),
		"flags": \(flags)
		"""
	}
}

extension Profile.Network.Account {
	public var accountAddress: AccountAddress {
		address
	}

	public mutating func hide() {
		flags.append(.deletedByUser)
	}

	public mutating func unhide() {
		flags.remove(.deletedByUser)
	}
}

extension Profile.Network.Accounts {
	public var nonHidden: IdentifiedArrayOf<Profile.Network.Account> {
		filter(not(\.isHidden)).asIdentifiable()
	}

	public var hidden: IdentifiedArrayOf<Profile.Network.Account> {
		filter(\.isHidden).asIdentifiable()
	}
}
