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

	/// Accounts created by the user for this network.
	public var accounts: NonEmpty<OrderedSet<Account>>

	/// Personas created by the user for this network.
	public var personas: OrderedSet<Persona>

	/// ConnectedDapp the user has connected with on this network.
	public var connectedDapps: OrderedSet<ConnectedDapp>

	public init(
		networkID: NetworkID,
		accounts: NonEmpty<OrderedSet<Account>>,
		personas: OrderedSet<Persona>,
		connectedDapps: OrderedSet<ConnectedDapp>
	) {
		self.networkID = networkID
		self.accounts = accounts
		self.personas = personas
		self.connectedDapps = connectedDapps
	}
}

public extension OnNetwork {
	var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"networkID": networkID,
				"accounts": accounts,
				"personas": personas,
				"connectedDapps": connectedDapps,
			],
			displayStyle: .struct
		)
	}

	var description: String {
		"""
		networkID: \(networkID),
		accounts: \(accounts),
		personas: \(personas),
		connectedDapps: \(connectedDapps),
		"""
	}
}
