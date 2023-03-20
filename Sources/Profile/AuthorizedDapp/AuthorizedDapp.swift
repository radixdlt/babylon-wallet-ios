import Prelude

// MARK: - Profile.Network.AuthorizedDapp
extension Profile.Network {
	/// A connection made between a Radix Dapp and the user.
	public struct AuthorizedDapp:
		Sendable,
		Hashable,
		Codable,
		Identifiable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		public let networkID: Radix.Network.ID

		public let dAppDefinitionAddress: DappDefinitionAddress

		public let displayName: NonEmpty<String>

		// mutable so that we can add new authorized personas
		public var referencesToAuthorizedPersonas: IdentifiedArrayOf<AuthorizedPersonaSimple>

		public init(
			networkID: Radix.Network.ID,
			dAppDefinitionAddress: DappDefinitionAddress,
			displayName: NonEmpty<String>,
			referencesToAuthorizedPersonas: IdentifiedArrayOf<AuthorizedPersonaSimple> = .init()
		) {
			self.networkID = networkID
			self.dAppDefinitionAddress = dAppDefinitionAddress
			self.displayName = displayName
			self.referencesToAuthorizedPersonas = referencesToAuthorizedPersonas
		}
	}
}

// MARK: - Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple
extension Profile.Network.AuthorizedDapp {
	public struct AuthorizedPersonaSimple:
		Sendable,
		Hashable,
		Identifiable,
		Codable
	{
		public typealias ID = IdentityAddress
		/// The globally unique identifier of a Persona is its address, used
		/// to lookup persona
		public let identityAddress: IdentityAddress

		/// List of "ongoing personaData" (identified by Profile.Network.Persona.Field.ID) that user has given the Dapp access to.
		/// mutable so that we can mutate the fields
		public var fieldIDs: OrderedSet<Profile.Network.Persona.Field.ID>

		/// Date of last login for this persona.
		public var lastLogin: Date

		/// List of "ongoing accountAddresses" that user given the dApp access to.
		public var sharedAccounts: SharedAccounts?

		public struct SharedAccounts:
			Sendable,
			Hashable,
			Codable
		{
			public struct NumberOfAccounts: Sendable, Hashable, Codable {
				public enum Quantifier: String, Sendable, Hashable, Codable {
					case exactly
					case atLeast
				}

				public let quantifier: Quantifier
				public let quantity: Int

				public static func exactly(_ quantity: Int) -> Self {
					.init(quantifier: .exactly, quantity: quantity)
				}

				public static func atLeast(_ quantity: Int) -> Self {
					.init(quantifier: .atLeast, quantity: quantity)
				}
			}

			public let request: NumberOfAccounts
			public private(set) var accountsReferencedByAddress: OrderedSet<AccountAddress>

			public init(
				accountsReferencedByAddress: OrderedSet<AccountAddress>,
				forRequest request: NumberOfAccounts
			) throws {
				try Self.validate(accountsReferencedByAddress: accountsReferencedByAddress, forRequest: request)
				self.request = request
				self.accountsReferencedByAddress = accountsReferencedByAddress
			}
		}

		public init(
			identityAddress: IdentityAddress,
			fieldIDs: OrderedSet<Profile.Network.Persona.Field.ID>,
			lastLogin: Date,
			sharedAccounts: SharedAccounts?
		) {
			self.identityAddress = identityAddress
			self.fieldIDs = fieldIDs
			self.lastLogin = lastLogin
			self.sharedAccounts = sharedAccounts
		}
	}
}

extension Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedAccounts {
	public static func validate(
		accountsReferencedByAddress: OrderedSet<AccountAddress>,
		forRequest request: NumberOfAccounts
	) throws {
		switch request.quantifier {
		case .atLeast:
			guard accountsReferencedByAddress.count >= request.quantity else {
				struct NotEnoughAccountsProvided: Swift.Error {}
				throw NotEnoughAccountsProvided()
			}
		// all good
		case .exactly:
			guard accountsReferencedByAddress.count == request.quantity else {
				struct InvalidNumberOfAccounts: Swift.Error {}
				throw InvalidNumberOfAccounts()
			}
			// all good
		}
	}

	public mutating func updateAccounts(_ new: OrderedSet<AccountAddress>) throws {
		try Self.validate(accountsReferencedByAddress: new, forRequest: self.request)
		self.accountsReferencedByAddress = new
	}
}

extension Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple {
	public var id: ID {
		identityAddress
	}
}

extension Profile.Network.AuthorizedDapp {
	public var id: DappDefinitionAddress {
		dAppDefinitionAddress
	}
}

extension Profile.Network.AuthorizedDapp {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"dAppDefinitionAddress": dAppDefinitionAddress,
				"displayName": String(describing: displayName),
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		dAppDefinitionAddress: \(dAppDefinitionAddress),
		displayName: \(String(describing: displayName)),
		"""
	}
}
