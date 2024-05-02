

// MARK: Add Persona
extension Profile {
	public mutating func addPersona(
		_ persona: Persona
	) throws {
		let networkID = persona.networkID
		var network = try network(id: networkID)
		try network.addPersona(persona)
		try updateOnNetwork(network)
	}

	public func hasAnyPersonaOnAnyNetwork() -> Bool {
		networks
			.map { $0.hasSomePersona() }
			.reduce(into: false) { $0 = $0 || $1 }
	}
}
