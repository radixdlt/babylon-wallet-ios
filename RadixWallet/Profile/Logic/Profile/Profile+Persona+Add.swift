import EngineToolkit

// MARK: - PersonaAlreadyExists
struct PersonaAlreadyExists: Swift.Error {}

// MARK: Add Persona
extension Profile {
	public mutating func addPersona(
		_ persona: Profile.Network.Persona
	) throws {
		let networkID = persona.networkID
		var network = try network(id: networkID)

		guard !network.personas.contains(where: { $0 == persona }) else {
			throw PersonaAlreadyExists()
		}

		let updatedElement = network.personas.updateOrAppend(persona)
		assert(updatedElement == nil, "We expected this to be a new, unique, Persona, thus we expected it to be have been inserted, but it was not. Maybe all properties except the IdentityAddress was unique, and the reason why address was not unique is probably due to the fact that the wrong 'index' in the derivation path was use (same reused), due to bad logic in `storage` of the factor.")

		try updateOnNetwork(network)
	}

	public func hasAnyPersonaOnAnyNetwork() -> Bool {
		networks.values
			.map(\.personas.isEmpty)
			.map { !$0 } // NOT isEmpty <=> has persona on network
			.reduce(into: false) { $0 = $0 || $1 }
	}

	public func hasAnyAccountOnAnyNetwork() -> Bool {
		networks.values
			.map(\.accounts.isEmpty)
			.map { !$0 } // NOT isEmpty <=> has account on network
			.reduce(into: false) { $0 = $0 || $1 }
	}

	public func hasMainnetAccounts() -> Bool {
		guard let mainnet = try? network(id: .mainnet) else {
			return false
		}
		return !mainnet.accounts.isEmpty
	}
}

// MARK: - Discrepancy
struct Discrepancy: Swift.Error {}
