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
		assert(updatedElement == nil, "We expected this to be a new, unique, Persona, thus we expected it to be have been inserted, but it was not. Maybe all properties except the IdentityAddress was unique, and the reason why address was not unique is probably due to the fact that the wrong 'index' in the derivation path was use (same reused), due to bad logic in `storage` of the factor.")

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
