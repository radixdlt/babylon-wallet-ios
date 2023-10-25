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
			.map { $0.hasAnyPersona() }
			.reduce(into: false) { $0 = $0 || $1 }
	}
}

// MARK: - Discrepancy
struct Discrepancy: Swift.Error {}
