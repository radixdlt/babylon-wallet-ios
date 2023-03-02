import EngineToolkit
import Prelude

extension Profile {
	internal mutating func updateOnNetwork(_ onNetwork: OnNetwork) throws {
		try perNetwork.update(onNetwork)
	}
}

extension Profile {
	/// The networkID of the current gateway.
	public var networkID: NetworkID {
		appPreferences.gateways.current.network.id
	}

	/// The current network with a non empty set of accounts.
	public var network: OnNetwork? {
		try? onNetwork(id: networkID)
	}

	public func onNetwork(id needle: NetworkID) throws -> OnNetwork {
		try perNetwork.onNetwork(id: needle)
	}

	public func containsNetwork(withID networkID: NetworkID) -> Bool {
		(try? onNetwork(id: networkID)) != nil
	}
}
