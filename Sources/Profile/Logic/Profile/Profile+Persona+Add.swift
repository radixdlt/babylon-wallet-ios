import EngineToolkit
import Foundation
import Prelude

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
		assert(updatedElement == nil)
		try updateOnNetwork(network)
		switch persona.securityState {
		case let .unsecured(entityControl):
			let factorSourceID = entityControl.genesisFactorInstance.factorSourceID
			try self.factorSources.updateFactorSource(id: factorSourceID) {
				try $0.increaseNextDerivationIndex(for: persona.kind, networkID: persona.networkID)
			}
		}
	}
}

// MARK: - Discrepancy
struct Discrepancy: Swift.Error {}
