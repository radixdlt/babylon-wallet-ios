import Foundation
import Sargon

extension Persona {
	public var shouldWriteDownMnemonic: Bool {
		let userDefaults = UserDefaults.Dependency.radix // FIXME: find a better way to ensure we use the same userDefaults everywhere

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
