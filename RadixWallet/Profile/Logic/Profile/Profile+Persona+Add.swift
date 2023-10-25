import EngineToolkit

// MARK: Add Persona
extension Profile {
	public mutating func addPersona(
		_ persona: Profile.Network.Persona
	) throws {
		let networkID = persona.networkID
		var network = try network(id: networkID)
		try network.addPersona(persona)
		try updateOnNetwork(network)
	}

	public func hasAnyPersonaOnAnyNetwork() -> Bool {
		networks.values
			.map { $0.getPersonas().isEmpty }
			.map { !$0 } // NOT isEmpty <=> has persona on network
			.reduce(into: false) { $0 = $0 || $1 }
	}

	public func hasAnyAccountOnAnyNetwork() -> Bool {
		networks.values
			.map { $0.getAccounts().isEmpty }
			.map { !$0 } // NOT isEmpty <=> has account on network
			.reduce(into: false) { $0 = $0 || $1 }
	}

	public func hasMainnetAccounts() -> Bool {
		guard let mainnet = try? network(id: .mainnet) else {
			return false
		}
		return !mainnet.getAccounts().isEmpty
	}
}

// MARK: - Discrepancy
struct Discrepancy: Swift.Error {}
