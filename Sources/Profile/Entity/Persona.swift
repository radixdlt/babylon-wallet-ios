import EngineToolkitModels
import Prelude

// MARK: - OnNetwork.Persona
extension OnNetwork {
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
		public let displayName: NonEmpty<String>

		/// Fields containing personal information you have inputted.
		public let fields: IdentifiedArrayOf<Field>

		public init(
			networkID: NetworkID,
			address: EntityAddress,
			securityState: EntitySecurityState,
			displayName: NonEmpty<String>,
			fields: IdentifiedArrayOf<Field>
		) {
			self.networkID = networkID
			self.address = address
			self.securityState = securityState
			self.fields = fields
			self.displayName = displayName
		}
	}
}

extension OnNetwork.Persona {
	public static var entityKind: EntityKind { .identity }

	public typealias EntityAddress = IdentityAddress

	/// A stable and globally unique identifier of an account.
	public typealias ID = EntityAddress

	/// A stable and globally unique identifier for this persona.
	public var id: ID { address }
}

extension OnNetwork.Persona {
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

// MARK: - OnNetwork.Persona.Field
extension OnNetwork.Persona {
	/// A field containing personal informations
	public struct Field:
		Sendable,
		Hashable,
		Codable,
		Identifiable,
		CustomStringConvertible,
		CustomDumpReflectable

	{
		/// A locally generated, globally unique ID for this personal information "field".
		public let id: ID

		/// Content type, e.g. `emailAddress` or `phoneNumber`
		public let kind: Kind

		/// The content of this field, a non empty string,
		/// e.g. "foo@bar.com" for email address or "555-5555" as phone number.
		public let value: Value

		public init(kind: Kind, value: Value) {
			self.id = ID()
			self.kind = kind
			self.value = value
		}
	}
}

import Cryptography
import EngineToolkit
extension OnNetwork.Persona {
	public static func deriveAddress(
		networkID: NetworkID,
		publicKey: SLIP10.PublicKey
	) throws -> EntityAddress {
		let response = try EngineToolkit().deriveVirtualIdentityAddressRequest(
			request: .init(
				publicKey: publicKey.intoEngine(),
				networkId: networkID
			)
		).get()

		return try EntityAddress(address: response.virtualIdentityAddress.address)
	}
}

extension OnNetwork.Persona.Field {
	public typealias ID = UUID
	public typealias Value = NonEmpty<String>

	public enum Kind:
		String,
		Sendable,
		Hashable,
		Codable,
		CustomStringConvertible,
		CustomDumpRepresentable
	{
		case givenName
		case familyName
		case emailAddress
		case phoneNumber
	}
}

extension OnNetwork.Persona.Field {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"id": id,
				"kind": kind,
				"value": value,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		"id": \(id),
		"kind": \(kind),
		"value": \(value)
		"""
	}
}

// MARK: - UUID + Sendable
extension UUID: @unchecked Sendable {}
