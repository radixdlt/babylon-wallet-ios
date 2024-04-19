import Sargon

extension Profile {
	mutating func updateOnNetwork(_ network: Sargon.ProfileNetwork) throws {
//		try networks.update(network)
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

extension Profile {
	/// The networkID of the current gateway.
	public var networkID: NetworkID {
		appPreferences.gateways.current.network.id
	}

	/// The current network with a non empty set of accounts.
	public var network: Sargon.ProfileNetwork? {
//		try? network(id: networkID)
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public func network(id needle: NetworkID) throws -> Sargon.ProfileNetwork {
		try networks.network(id: needle)
	}

	public func containsNetwork(withID networkID: NetworkID) -> Bool {
//		(try? network(id: networkID)) != nil
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
