

// MARK: Add Persona
extension Profile {
	public mutating func addPersona(
		_ persona: Persona
	) throws {
//		let networkID = persona.networkID
//		var network = try network(id: networkID)
//		try network.addPersona(persona)
//		try updateOnNetwork(network)
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public func hasAnyPersonaOnAnyNetwork() -> Bool {
//		networks.values
//			.map { $0.hasSomePersona() }
//			.reduce(into: false) { $0 = $0 || $1 }
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - Discrepancy
struct Discrepancy: Swift.Error {}
