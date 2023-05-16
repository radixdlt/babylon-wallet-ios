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

		public let dAppDefinitionAddress: AccountAddress

		/// Will be nil if the `dAppDefinitionAddress` is `invalid` and thus we fialed to fetch
		/// the name from Ledger (metadata on the entity)
		public let displayName: NonEmptyString?

		// mutable so that we can add new authorized personas
		public var referencesToAuthorizedPersonas: IdentifiedArrayOf<AuthorizedPersonaSimple>

		public init(
			networkID: Radix.Network.ID,
			dAppDefinitionAddress: AccountAddress,
			displayName: NonEmptyString?,
			referencesToAuthorizedPersonas: IdentifiedArrayOf<AuthorizedPersonaSimple> = .init()
		) {
			self.networkID = networkID
			self.dAppDefinitionAddress = dAppDefinitionAddress
			self.displayName = displayName
			self.referencesToAuthorizedPersonas = referencesToAuthorizedPersonas
		}
	}
}

extension Profile.Network.AuthorizedDapp {
	public var id: AccountAddress {
		dAppDefinitionAddress
	}
}

// MARK: - DappOriginTag
public enum DappOriginTag {}
public typealias DappOrigin = Tagged<DappOriginTag, NonEmptyString>

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

		/// Date of last login for this persona.
		public var lastLogin: Date

		/// List of "ongoing accountAddresses" that user given the dApp access to.
		public var sharedAccounts: SharedAccounts?

		/// List of "ongoing personaData" (identified by Profile.Network.Persona.Field.ID) that user has given the Dapp access to.
		/// mutable so that we can mutate the fields
		public var sharedFieldIDs: Set<Profile.Network.Persona.Field.ID>?

		public struct SharedAccounts:
			Sendable,
			Hashable,
			Codable
		{
			// TODO: evolve this into an enum mirroring `SelectionRequirement` in `Selection.swift` to enable case switching.
			//
			// Things to keep in mind:
			//
			// - It will require a custom Codable implementation to make up for the move from struct(ured) to enum. Make sure implementation matches CAP-21's spec by writing some XCTAssertJSON tests beforehand.
			// - Don't just typealias NumberOfAccounts = SelectionRequirement, as they're not the same conceptually and should be allowed to evolve independently!
			public struct NumberOfAccounts: Sendable, Hashable, Codable {
				public enum Quantifier: String, Sendable, Hashable, Codable {
					case exactly
					case atLeast
				}

				public let quantifier: Quantifier
				public let quantity: Int

				public var isValid: Bool {
					switch (quantifier, quantity) {
					case (.exactly, 0):
						return false
					case (_, ..<0):
						return false
					default:
						return true
					}
				}

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
			lastLogin: Date,
			sharedAccounts: SharedAccounts?,
			sharedFieldIDs: Set<Profile.Network.Persona.Field.ID>?
		) {
			self.identityAddress = identityAddress
			self.lastLogin = lastLogin
			self.sharedAccounts = sharedAccounts
			self.sharedFieldIDs = sharedFieldIDs
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
