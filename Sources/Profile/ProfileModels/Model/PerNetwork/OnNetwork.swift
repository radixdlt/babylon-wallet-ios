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

	/// A **Non-empty** identifiable ordered set of `Account`s created by the user for this network.
	public var accounts: NonEmpty<IdentifiedArrayOf<Account>>

	/// An Identifiable ordered set of `Persona`s created by the user for this network.
	public var personas: IdentifiedArrayOf<Persona>

	/// An Identifiable ordered set of `ConnectedDapp`s the user has connected to.
	public var connectedDapps: IdentifiedArrayOf<ConnectedDapp>

	public init(
		networkID: NetworkID,
		accounts: NonEmpty<IdentifiedArrayOf<Account>>,
		personas: IdentifiedArrayOf<Persona>,
		connectedDapps: IdentifiedArrayOf<ConnectedDapp>
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
