import Sargon

extension Profile {
	mutating func updateOnNetwork(_ network: ProfileNetwork) throws {
		try networks.update(network)
	}
}

extension Profile {
	/// The networkID of the current gateway.
	public var networkID: NetworkID {
		appPreferences.gateways.current.network.id
	}

	/// The current network with a non empty set of accounts.
	public var network: ProfileNetwork? {
		try? network(id: networkID)
	}

	public func network(id needle: NetworkID) throws -> ProfileNetwork {
		try networks.network(id: needle)
	}

	public func containsNetwork(withID networkID: NetworkID) -> Bool {
		(try? network(id: networkID)) != nil
	}
}
