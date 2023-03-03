import EngineToolkit
import Foundation
import Prelude

// MARK: - PersonaAlreadyExists
struct PersonaAlreadyExists: Swift.Error {}

// MARK: Add Persona
extension Profile {
	public mutating func addPersona(
		_ persona: OnNetwork.Persona
	) throws {
		let networkID = persona.networkID
		var onNetwork = try onNetwork(id: networkID)

		guard !onNetwork.personas.contains(where: { $0 == persona }) else {
			throw PersonaAlreadyExists()
		}

		let updatedElement = onNetwork.personas.updateOrAppend(persona)
		assert(updatedElement == nil)
		try updateOnNetwork(onNetwork)
	}
}
