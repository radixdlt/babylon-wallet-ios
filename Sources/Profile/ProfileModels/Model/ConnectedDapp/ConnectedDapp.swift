import Prelude

// MARK: - OnNetwork.ConnectedDapp
public extension OnNetwork {
	/// A connection made between a Radix Dapp and the user.
	struct ConnectedDapp:
		Sendable,
		Hashable,
		Codable,
		Identifiable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		public let networkID: Network.ID

		public let dAppDefinitionAddress: DappDefinitionAddress

		public let displayName: String

		// mutable so that we can add new authorized personas
		public var referencesToAuthorizedPersonas: OrderedSet<AuthorizedPersonaSimple>
	}
}

// MARK: - OnNetwork.ConnectedDapp.AuthorizedPersonaSimple
public extension OnNetwork.ConnectedDapp {
	struct AuthorizedPersonaSimple:
		Sendable,
		Hashable,
		Codable
	{
		/// The globally unique identifier of a Persona is its address, used
		/// to lookup persona
		public let identityAddress: IdentityAddress

		/// List of "ongoing personaData" (identified by OnNetwork.Persona.Field.ID) that user has given the Dapp access to.
		/// mutable so that we can mutate the fields
		public var fieldIDs: OrderedSet<OnNetwork.Persona.Field.ID>

		/// List of "ongoing accountAddresses" that user given the dApp access to.
		public var sharedAccounts: SharedAccounts

		public struct SharedAccounts:
			Sendable,
			Hashable,
			Codable
		{
			public let mode: Mode.Stripped

			// FIXME: When we have **value** generics we would use something like:
			// `OrderedSet<N; AccountAddress` (however that would be encodoed)
			public private(set) var accountsReferencedByAddress: OrderedSet<AccountAddress>

			public mutating func updateAccounts(_ new: OrderedSet<AccountAddress>) throws {
				switch self.mode {
				case .exactly:
					guard new.count == self.accountsReferencedByAddress.count else {
						struct MustBeExactlyAccountLength: Swift.Error {}
						throw MustBeExactlyAccountLength()
					}
					self.accountsReferencedByAddress = new
				case .orMore:
					guard new.count >= self.accountsReferencedByAddress.count else {
						struct MustBeSameOrMoreAccounts: Swift.Error {}
						throw MustBeSameOrMoreAccounts()
					}
					self.accountsReferencedByAddress = new
				}
			}

			public enum Mode {
				case exactly(OrderedSet<AccountAddress>)
				case orMore(OrderedSet<AccountAddress>)

				public enum Stripped:
					Sendable,
					Hashable,
					Codable
				{
					case exactly
					case orMore
				}
			}

			public init(
				mode: Mode
			) throws {
				switch mode {
				case let .orMore(accounts):
					self.mode = .orMore
					self.accountsReferencedByAddress = accounts
				case let .exactly(accounts):
					self.mode = .exactly
					self.accountsReferencedByAddress = accounts
				}
			}
		}

		public init(
			identityAddress: IdentityAddress,
			fieldIDs: OrderedSet<OnNetwork.Persona.Field.ID>,
			sharedAccounts: SharedAccounts
		) {
			self.identityAddress = identityAddress
			self.fieldIDs = fieldIDs
			self.sharedAccounts = sharedAccounts
		}
	}
}

public extension OnNetwork.ConnectedDapp {
	var id: DappDefinitionAddress {
		dAppDefinitionAddress
	}
}

public extension OnNetwork.ConnectedDapp {
	var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"dAppDefinitionAddress": dAppDefinitionAddress,
				"displayName": String(describing: displayName),
			],
			displayStyle: .struct
		)
	}

	var description: String {
		"""
		dAppDefinitionAddress: \(dAppDefinitionAddress),
		displayName: \(String(describing: displayName)),
		"""
	}
}
