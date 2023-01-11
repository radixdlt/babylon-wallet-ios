import Collections
import CustomDump
import Foundation
import NonEmpty

// MARK: - NonEmpty + Sendable
extension NonEmpty: @unchecked Sendable where Element: Sendable {}

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
	public internal(set) var accounts: NonEmpty<OrderedSet<Account>>

	/// Personas created by the user for this network.
	public internal(set) var personas: OrderedSet<Persona>

	/// ConnectedDapp the user has connected with on this network.
	public internal(set) var connectedDapps: OrderedSet<ConnectedDapp>
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
