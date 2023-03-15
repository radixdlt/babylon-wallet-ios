import EngineToolkitModels
import Prelude

// MARK: - OnNetwork
/// **For a given network**: a list of accounts, personas and connected dApps.
public struct OnNetwork:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	/// The ID of the network that has been used to generate the accounts, to which personas
	/// have been added and dApps connected.
	public let networkID: NetworkID

	public typealias Accounts = NonEmpty<IdentifiedArrayOf<Account>>
	/// A **Non-empty** identifiable ordered set of `Account`s created by the user for this network.
	public var accounts: Accounts

	public typealias Personas = IdentifiedArrayOf<Persona>
	/// An identifiable ordered set of `Persona`s created by the user for this network.
	public var personas: Personas

	public typealias AuthorizedDapps = IdentifiedArrayOf<AuthorizedDapp>
	/// An identifiable ordered set of `AuthorizedDapp`s the user has connected to.
	public var authorizedDapps: AuthorizedDapps

	public init(
		networkID: NetworkID,
		accounts: Accounts,
		personas: Personas,
		authorizedDapps: AuthorizedDapps
	) {
		self.networkID = networkID
		self.accounts = accounts
		self.personas = personas
		self.authorizedDapps = authorizedDapps
	}
}

extension OnNetwork {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"networkID": networkID,
				"accounts": accounts,
				"personas": personas,
				"authorizedDapps": authorizedDapps,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		networkID: \(networkID),
		accounts: \(accounts),
		personas: \(personas),
		authorizedDapps: \(authorizedDapps),
		"""
	}
}
