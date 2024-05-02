import Foundation
import Sargon

extension Persona {
	public var shouldWriteDownMnemonic: Bool {
		let userDefaults = UserDefaults.Dependency.radix // FIXME: find a better way to ensure we use the same userDefaults everywhere

		@Dependency(\.secureStorageClient) var secureStorageClient

		guard
			let deviceFactorSourceID,
			secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(deviceFactorSourceID)
		else {
			// Can't write down, what you dont have.
			return false
		}

		let backedUpIds = userDefaults.getFactorSourceIDOfBackedUpMnemonics()
		let alreadyBackedUp = backedUpIds.contains(deviceFactorSourceID)
		return !alreadyBackedUp
	}
}
