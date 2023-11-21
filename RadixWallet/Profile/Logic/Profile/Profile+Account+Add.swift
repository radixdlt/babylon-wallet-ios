import EngineToolkit

// MARK: - PersonaNotConnected
struct PersonaNotConnected: Swift.Error {}

// MARK: - TryingToUpdateAnAccountWhichIsNotAlreadySaved
struct TryingToUpdateAnAccountWhichIsNotAlreadySaved: Swift.Error {}

extension Profile {
	/// Updates an `Account` in the profile
	public mutating func updateAccount(
		_ account: Profile.Network.Account
	) throws {
		var network = try network(id: account.networkID)
		try network.updateAccount(account)
		try updateOnNetwork(network)
	}

	/// Saves an `Account` into the profile, if this is the first mainnet account,
	/// we will switch to mainnet
	public mutating func addAccount(
		_ account: Profile.Network.Account
	) throws {
		let networkID = account.networkID
		// can be nil if this is a new network
		let maybeNetwork = try? network(id: networkID)

		if var network = maybeNetwork {
			try network.addAccount(account)
			try updateOnNetwork(network)
		} else {
			let network = Profile.Network(
				networkID: networkID,
				accounts: [account].asIdentifiable(),
				personas: [],
				authorizedDapps: []
			)
			try networks.add(network)

			if network.networkID == .mainnet {
				do {
					try changeGateway(to: .mainnet)
				} catch {
					let errorMsg = "Failed to switch to mainnet, even though we just created a first mainnet account, error: \(error)"
					loggerGlobal.critical(.init(stringLiteral: errorMsg))
					assertionFailure(errorMsg) // for production, we will not crash
				}
			}
		}
	}
}

// MARK: - DisrepancyFactorSourceWrongKind
public struct DisrepancyFactorSourceWrongKind: Swift.Error {
	public let expected: FactorSourceKind
	public let actual: FactorSourceKind
}
