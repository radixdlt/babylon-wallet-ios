import EngineToolkit

// MARK: - Profile.Network.Persona
extension Profile.Network {
	/// A network unique account with a unique public address and a set of cryptographic
	/// factors used to control it. The account is either `virtual` or not. By "virtual"
	/// we mean that the Radix Public Ledger does not yet know of the public address
	/// of this account.
	public struct Persona:
		EntityProtocol,
		Sendable,
		Hashable,
		Codable,
		Identifiable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		/// The ID of the network this persona exists on.
		public let networkID: NetworkID

		/// The globally unique and identifiable Radix component address of this persona. Can be used as
		/// a stable ID. Cryptographically derived from a seeding public key which typically was created by
		/// the `DeviceFactorSource`
		public let address: EntityAddress

		/// Security of this persona
		public var securityState: EntitySecurityState

		/// A required non empty display name, used by presentation layer and sent to Dapps when requested.
		public var displayName: NonEmptyString

		/// Flags that are currently set on entity.
		@DefaultCodable.EmptyCollection
		public var flags: Flags

		public var personaData: PersonaData

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
			self.personaData = extraProperties.personaData
		}

		public init(
			networkID: NetworkID,
			address: EntityAddress,
			securityState: EntitySecurityState,
			displayName: NonEmpty<String>
		) {
			self.init(
				networkID: networkID,
				address: address,
				securityState: securityState,
				displayName: displayName,
				extraProperties: .init(personaData: .init())
			)
		}
	}
}

extension Profile.Network.Persona {
	/// Ephemeral, only used as arg passed to init.
	public struct ExtraProperties: Sendable, Hashable, Codable {
		public var personaData: PersonaData
		public init(personaData: PersonaData) {
			self.personaData = personaData
		}
	}

	public init(
		networkID: NetworkID,
		address: EntityAddress,
		securityState: EntitySecurityState,
		displayName: NonEmpty<String>,
		personaData: PersonaData
	) {
		self.init(
			networkID: networkID,
			address: address,
			securityState: securityState,
			displayName: displayName,
			extraProperties: .init(personaData: personaData)
		)
	}

	public static var entityKind: EntityKind { .identity }

	/// Noop
	public mutating func updateAppearanceIDIfAble(_: Profile.Network.Account.AppearanceID) {}

	public typealias EntityAddress = IdentityAddress
}

extension Profile.Network.Persona {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"address": address,
				"securityState": securityState,
				"personaData": personaData,
				"displayName": String(describing: displayName),
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		"displayName": \(String(describing: displayName)),
		"address": \(address),
		"securityState": \(securityState),
		"personaData": \(personaData)
		"""
	}
}

extension Profile.Network.Persona {
	public static func deriveVirtualAddress(
		networkID: NetworkID,
		factorInstance: HierarchicalDeterministicFactorInstance
	) throws -> EntityAddress {
		let path = try factorInstance.derivationPath.asIdentityPath()
		guard path.entityKind == .identity else {
			throw WrongEntityInDerivationPath()
		}

		let engineAddress = try deriveVirtualIdentityAddressFromPublicKey(
			publicKey: factorInstance.publicKey.intoEngine(),
			networkId: networkID.rawValue
		)

		return .init(address: engineAddress.addressString(), decodedKind: engineAddress.entityType())
	}
}

extension Profile.Network.Persona {
	public mutating func hide() {
		flags.append(.deletedByUser)
	}

	public mutating func unhide() {
		flags.remove(.deletedByUser)
	}
}

extension Profile.Network.Personas {
	public var nonHidden: IdentifiedArrayOf<Profile.Network.Persona> {
		filter(not(\.isHidden)).asIdentified()
	}

	public var hiden: IdentifiedArrayOf<Profile.Network.Persona> {
		filter(\.isHidden).asIdentified()
	}
}

extension Profile.Network.Persona {
	public var shouldWriteDownMnemonic: Bool {
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.secureStorageClient) var secureStorageClient

		guard let deviceFactorSourceID else {
			return false
		}

		guard
			secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(deviceFactorSourceID)
		else {
			loggerGlobal.trace("SHOULD write down seed phrase for persona: \(self), factorSource: \(deviceFactorSourceID)")
			// Can't write down, what you dont have.
			return false
		}

		let backedUpIds = userDefaults.getFactorSourceIDOfBackedUpMnemonics()
		let alreadyBackedUp = backedUpIds.contains(deviceFactorSourceID)
		loggerGlobal.trace("SHOULD write down seed phrase for persona: \(self), factorSource: \(deviceFactorSourceID)")
		return !alreadyBackedUp
	}
}
