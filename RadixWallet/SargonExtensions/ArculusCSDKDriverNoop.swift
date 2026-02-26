import Foundation
import SargonUniFFI

final class ArculusCSDKDriver: SargonUniFFI.ArculusCsdkDriver {
	func seedPhraseFromMnemonicSentence(wallet: SargonUniFFI.ArculusWalletPointer, mnemonicSentence: Data, passphrase: Data?) -> Data? {
		nil
	}

	func walletInit() -> SargonUniFFI.ArculusWalletPointer? {
		nil
	}

	func walletFree(wallet: SargonUniFFI.ArculusWalletPointer) {}
	func selectWalletRequest(wallet: SargonUniFFI.ArculusWalletPointer, aid: Data) -> Data? {
		nil
	}

	func selectWalletResponse(wallet: SargonUniFFI.ArculusWalletPointer, response: Data) -> Data? {
		nil
	}

	func createWalletSeedRequest(wallet: SargonUniFFI.ArculusWalletPointer, wordCount: Int64) -> Data? {
		nil
	}

	func createWalletSeedResponse(wallet: SargonUniFFI.ArculusWalletPointer, response: Data) -> Data? {
		nil
	}

	func resetWalletRequest(wallet: SargonUniFFI.ArculusWalletPointer) -> Data? {
		nil
	}

	func resetWalletResponse(wallet: SargonUniFFI.ArculusWalletPointer, response: Data) -> Int32 {
		-1
	}

	func getGguidRequest(wallet: SargonUniFFI.ArculusWalletPointer) -> Data? {
		nil
	}

	func getGguidResponse(wallet: SargonUniFFI.ArculusWalletPointer, response: Data) -> Data? {
		nil
	}

	func getFirmwareVersionRequest(wallet: SargonUniFFI.ArculusWalletPointer) -> Data? {
		nil
	}

	func getFirmwareVersionResponse(wallet: SargonUniFFI.ArculusWalletPointer, response: Data) -> Data? {
		nil
	}

	func storeDataPinRequest(wallet: SargonUniFFI.ArculusWalletPointer, pin: String) -> Data? {
		nil
	}

	func storeDataPinResponse(wallet: SargonUniFFI.ArculusWalletPointer, response: Data) -> Int32 {
		-1
	}

	func verifyPinRequest(wallet: SargonUniFFI.ArculusWalletPointer, pin: String) -> Data? {
		nil
	}

	func verifyPinResponse(wallet: SargonUniFFI.ArculusWalletPointer, response: Data) -> SargonUniFFI.ArculusVerifyPinResponse {
		.init(status: -1, numberOfTriesRemaining: 0)
	}

	func initEncryptedSessionRequest(wallet: SargonUniFFI.ArculusWalletPointer) -> Data? {
		nil
	}

	func initEncryptedSessionResponse(wallet: SargonUniFFI.ArculusWalletPointer, response: Data) -> Int32 {
		-1
	}

	func getPublicKeyByPathRequest(wallet: SargonUniFFI.ArculusWalletPointer, path: Data, curve: UInt16) -> Data? {
		nil
	}

	func getPublicKeyByPathResponse(wallet: SargonUniFFI.ArculusWalletPointer, response: Data) -> Data? {
		nil
	}

	func signHashPathRequest(wallet: SargonUniFFI.ArculusWalletPointer, path: Data, curve: UInt16, algorithm: UInt8, hash: Data) -> [Data]? {
		nil
	}

	func signHashPathResponse(wallet: SargonUniFFI.ArculusWalletPointer, response: Data) -> Data? {
		nil
	}

	func initRecoverWalletRequest(wallet: SargonUniFFI.ArculusWalletPointer, wordCount: Int64) -> Data? {
		nil
	}

	func initRecoverWalletResponse(wallet: SargonUniFFI.ArculusWalletPointer, response: Data) -> Int32 {
		-1
	}

	func finishRecoverWalletRequest(wallet: SargonUniFFI.ArculusWalletPointer, seed: Data) -> Data? {
		nil
	}

	func finishRecoverWalletResponse(wallet: SargonUniFFI.ArculusWalletPointer, response: Data) -> Int32 {
		-1
	}
}
