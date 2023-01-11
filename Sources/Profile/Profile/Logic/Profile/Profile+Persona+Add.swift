import EngineToolkit
import Foundation

// MARK: Create Persona
public extension Profile {
	/// Creates a new **Virtual** `Persona` without saving it anywhere
	static func createNewVirtualPersona(
		factorSources: FactorSources,
		personaIndex: Int,
		networkID: NetworkID,
		displayName: String? = nil,
		fields: [OnNetwork.Persona.Field] = [],
		createFactorInstance: @escaping CreateFactorInstanceForRequest
	) async throws -> OnNetwork.Persona {
		try await OnNetwork.createNewVirtualEntity(
			factorSources: factorSources,
			index: personaIndex,
			networkID: networkID,
			displayName: displayName,
			createFactorInstance: createFactorInstance,
			makeEntity: {
				OnNetwork.Persona(
					address: $0,
					securityState: $1,
					index: $2,
					derivationPath: $3,
					displayName: $4,
					fields: fields
				)
			}
		)
	}
}

// MARK: Add Persona
public extension Profile {
	/// Creates a new **Virtual**  `Persona` and saves it into the profile.
	@discardableResult
	mutating func createNewVirtualPersona(
		networkID: NetworkID,
		displayName: String? = nil,
		fields: [OnNetwork.Persona.Field] = [],
		createFactorInstance: @escaping CreateFactorInstanceForRequest
	) async throws -> OnNetwork.Persona {
		var onNetwork = try onNetwork(id: networkID)

		let persona = try await Self.createNewVirtualPersona(
			factorSources: self.factorSources,
			personaIndex: onNetwork.personas.count,
			networkID: networkID,
			displayName: displayName,
			fields: fields,
			createFactorInstance: createFactorInstance
		)

		let updatedElement = onNetwork.personas.updateOrAppend(persona)
		assert(updatedElement == nil)
		try updateOnNetwork(onNetwork)

		return persona
	}
}
