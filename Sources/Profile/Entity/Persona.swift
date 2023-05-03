import EngineToolkitModels
import Prelude

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
		public var displayName: NonEmpty<String>

		/// Fields containing personal information you have inputted.
		public var fields: IdentifiedArrayOf<Field>

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
			self.fields = extraProperties.fields
			self.displayName = displayName
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
				fields: []
			)
		}
	}
}

extension Profile.Network.Persona {
	/// Ephemeral, only used as arg passed to init.
	public struct ExtraProperties: Sendable, Hashable, Codable {
		public var fields: IdentifiedArrayOf<Field>
		public init(fields: IdentifiedArrayOf<Field> = []) {
			self.fields = fields
		}
	}

	public init(
		networkID: NetworkID,
		address: EntityAddress,
		securityState: EntitySecurityState,
		displayName: NonEmpty<String>,
		fields: IdentifiedArrayOf<Field>
	) {
		self.init(networkID: networkID, address: address, securityState: securityState, displayName: displayName, extraProperties: .init(fields: fields))
	}

	public static var entityKind: EntityKind { .identity }

	/// Noop
	public mutating func updateAppearanceIDIfAble(_: Profile.Network.Account.AppearanceID) {}

	public typealias EntityAddress = IdentityAddress

	/// A stable and globally unique identifier of an account.
	public typealias ID = EntityAddress

	/// A stable and globally unique identifier for this persona.
	public var id: ID { address }
}

extension Profile.Network.Persona {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"address": address,
				"securityState": securityState,
				"fields": fields,
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
		"fields": \(fields)
		"""
	}
}

// MARK: - Profile.Network.Persona.Field
extension Profile.Network.Persona {
	/// A field containing personal informations
	public struct Field:
		Sendable,
		Hashable,
		Codable,
		Identifiable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		public enum ID:
			String,
			Sendable,
			Hashable,
			Codable,
			CaseIterable,
			CustomStringConvertible,
			CustomDumpRepresentable
		{
			case givenName
			case familyName
			case emailAddress
			case phoneNumber
		}

		public typealias Value = NonEmpty<String>

		/// Field identifier, e.g. `emailAddress` or `phoneNumber`.
		public let id: ID

		/// The content of this field, a non empty string,
		/// e.g. "foo@bar.com" for email address or "555-5555" as phone number.
		public let value: Value

		public init(id: ID, value: Value) {
			self.id = id
			self.value = value
		}
	}
}

import Cryptography
import EngineToolkit
extension Profile.Network.Persona {
	public static func deriveAddress(
		networkID: NetworkID,
		factorInstance: FactorInstance
	) throws -> EntityAddress {
		if let derivationPath = factorInstance.derivationPath {
			let path = try derivationPath.asIdentityPath()
			guard path.entityKind == .identity else {
				throw WrongEntityInDerivationPath()
			}
		}

		let response = try EngineToolkit().deriveVirtualIdentityAddressRequest(
			request: .init(
				publicKey: factorInstance.publicKey.intoEngine(),
				networkId: networkID
			)
		).get()

		return try EntityAddress(address: response.virtualIdentityAddress.address)
	}
}

// MARK: - Profile.Network.Persona.Field.ID + Comparable
extension Profile.Network.Persona.Field.ID: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		guard
			let lhsIndex = Self.allCases.firstIndex(of: lhs),
			let rhsIndex = Self.allCases.firstIndex(of: rhs)
		else {
			assertionFailure(
				"""
				This code path should never occur, unless you're manually conforming to `CaseIterable` and `allCases` is incomplete.
				"""
			)
			return false
		}
		return lhsIndex < rhsIndex
	}
}

extension Profile.Network.Persona.Field {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"id": id,
				"value": value,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		"id": \(id),
		"value": \(value)
		"""
	}
}
