import EngineToolkit
import Prelude

extension Profile {
	internal mutating func updateOnNetwork(_ onNetwork: Profile.Network) throws {
		try networks.update(onNetwork)
	}
}

extension Profile {
	/// The networkID of the current gateway.
	public var networkID: NetworkID {
		appPreferences.gateways.current.network.id
	}

	/// The current network with a non empty set of accounts.
	public var network: Profile.Network? {
		try? onNetwork(id: networkID)
	}

	public func onNetwork(id needle: NetworkID) throws -> Profile.Network {
		try networks.onNetwork(id: needle)
	}

	public func containsNetwork(withID networkID: NetworkID) -> Bool {
		(try? onNetwork(id: networkID)) != nil
	}
}
