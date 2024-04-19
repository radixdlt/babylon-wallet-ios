import Foundation
import Sargon

extension Persona {
	public mutating func hide() {
//		flags.append(.deletedByUser)
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public mutating func unhide() {
//		flags.remove(.deletedByUser)
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

extension Personas {
	public var nonHidden: IdentifiedArrayOf<Sargon.Persona> {
		filter(not(\.isHidden)).asIdentified()
	}

	public var hiden: IdentifiedArrayOf<Sargon.Persona> {
		filter(\.isHidden).asIdentified()
	}
}

extension Persona {
	public var shouldWriteDownMnemonic: Bool {
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.secureStorageClient) var secureStorageClient

		guard let deviceFactorSourceID else {
			return false
		}

		guard
			secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(deviceFactorSourceID)
		else {
			loggerGlobal.trace("SHOULD write down seed phrase for persona: \(self), factorSource: \(deviceFactorSourceID)")
			// Can't write down, what you dont have.
			return false
		}

		let backedUpIds = userDefaults.getFactorSourceIDOfBackedUpMnemonics()
		let alreadyBackedUp = backedUpIds.contains(deviceFactorSourceID)
		loggerGlobal.trace("SHOULD write down seed phrase for persona: \(self), factorSource: \(deviceFactorSourceID)")
		return !alreadyBackedUp
	}
}
