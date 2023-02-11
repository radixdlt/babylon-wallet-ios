import EngineToolkit
import Foundation
import Prelude

// MARK: Add Persona
extension Profile {
	/// Creates a new **Virtual** `Persona` and saves it into the profile, by trying to load
	/// mnemonics using `mnemonicForFactorSourceByReference`, to create factor instances for this new Persona.
	@discardableResult
	public mutating func createNewVirtualPersona(
		networkID: NetworkID,
		displayName: NonEmpty<String>,
		fields: IdentifiedArrayOf<OnNetwork.Persona.Field> = .init(),
		mnemonicForFactorSourceByReference: @escaping MnemonicForFactorSourceByReference
	) async throws -> OnNetwork.Persona {
		try await createNewVirtualPersona(
			networkID: networkID,
			displayName: displayName,
			fields: fields,
			createFactorInstance: mnemonicForFactorSourceByReferenceToCreateFactorInstance(
				includePrivateKey: false,
				mnemonicForFactorSourceByReference
			)
		)
	}

	/// Creates a new **Virtual** `Persona` and saves it into the profile.
	@discardableResult
	public mutating func createNewVirtualPersona(
		networkID: NetworkID,
		displayName: NonEmpty<String>,
		fields: IdentifiedArrayOf<OnNetwork.Persona.Field> = .init(),
		createFactorInstance: @escaping CreateFactorInstanceForRequest
	) async throws -> OnNetwork.Persona {
		let persona = try await creatingNewVirtualPersona(
			networkID: networkID,
			displayName: displayName,
			fields: fields,
			createFactorInstance: createFactorInstance
		)

		try await addPersona(persona)
		return persona
	}

	public mutating func addPersona(
		_ persona: OnNetwork.Persona
	) async throws {
		let networkID = persona.networkID
		var onNetwork = try onNetwork(id: networkID)

		guard !onNetwork.personas.contains(where: { $0 == persona }) else {
			throw PersonaAlreadyExists()
		}

		let updatedElement = onNetwork.personas.updateOrAppend(persona)
		assert(updatedElement == nil)
		try updateOnNetwork(onNetwork)
	}

	/// Creates a new **Virtual**  `Persona` without saving it into the profile.
	public func creatingNewVirtualPersona(
		networkID: NetworkID,
		displayName: NonEmpty<String>,
		fields: IdentifiedArrayOf<OnNetwork.Persona.Field> = .init(),
		mnemonicForFactorSourceByReference: @escaping MnemonicForFactorSourceByReference
	) async throws -> OnNetwork.Persona {
		try await creatingNewVirtualPersona(networkID: networkID, displayName: displayName, fields: fields, createFactorInstance: mnemonicForFactorSourceByReferenceToCreateFactorInstance(
			includePrivateKey: false,
			mnemonicForFactorSourceByReference
		))
	}

	/// Creates a new **Virtual**  `Persona` without saving it into the profile.
	public func creatingNewVirtualPersona(
		networkID: NetworkID,
		displayName: NonEmpty<String>,
		fields: IdentifiedArrayOf<OnNetwork.Persona.Field> = .init(),
		createFactorInstance: @escaping CreateFactorInstanceForRequest
	) async throws -> OnNetwork.Persona {
		let onNetwork = try onNetwork(id: networkID)

		let persona = try await Self.createNewVirtualPersona(
			factorSources: self.factorSources,
			personaIndex: onNetwork.personas.count,
			networkID: networkID,
			displayName: displayName,
			fields: fields,
			createFactorInstance: createFactorInstance
		)

		return persona
	}

	/// Creates a new **Virtual** `Persona` without saving it anywhere
	public static func createNewVirtualPersona(
		factorSources: FactorSources,
		personaIndex: Int,
		networkID: NetworkID,
		displayName: NonEmpty<String>,
		fields: IdentifiedArrayOf<OnNetwork.Persona.Field> = .init(),
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
					networkID: networkID,
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
