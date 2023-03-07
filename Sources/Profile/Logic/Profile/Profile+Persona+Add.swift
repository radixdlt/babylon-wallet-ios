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
		switch persona.securityState {
		case let .unsecured(entityControl):
			let factorSourceID = entityControl.genesisFactorInstance.factorSourceID
			try self.factorSources.updateFactorSource(id: factorSourceID) {
				try $0.increaseNextDerivationIndex(for: .identity)
			}
		}
	}
}

// MARK: - Discrepancy
struct Discrepancy: Swift.Error {}

extension FactorSource {
	public mutating func increaseNextDerivationIndex(for entityKind: EntityKind) throws {
		try storage?.increaseNextDerivationIndex(for: entityKind)
	}
}

extension FactorSource.Storage {
	public mutating func increaseNextDerivationIndex(for entityKind: EntityKind) throws {
		switch self {
		case .forSecurityQuestions: throw Discrepancy()
		case var .forDevice(deviceStorage):
			deviceStorage.increaseNextDerivationIndex(for: entityKind)
			self = .forDevice(deviceStorage)
		}
	}
}

extension DeviceStorage {
	public mutating func increaseNextDerivationIndex(for entityKind: EntityKind) {
		nextDerivationIndicies.increaseNextDerivationIndex(for: entityKind)
	}
}

extension NextDerivationIndicies {
	public mutating func increaseNextDerivationIndex(for entityKind: EntityKind) {
		switch entityKind {
		case .account: self.forAccount += 1
		case .identity: self.forIdentity += 1
		}
	}
}
