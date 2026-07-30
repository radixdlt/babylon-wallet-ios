import Foundation
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - DeviceMnemonicFactorSourceAccessTests
@MainActor
final class DeviceMnemonicFactorSourceAccessTests: TestCase {
	func testStoredMnemonicIsReturnedForDeviceAccess() async {
		let privateFactorSource = PrivateHierarchicalDeterministicFactorSource.testValueZooVote
		let factorSource = privateFactorSource.factorSource
		let mnemonicWithPassphrase = privateFactorSource.mnemonicWithPassphrase
		let store = TestStore(
			initialState: FactorSourceAccess.State(factorSource: factorSource.asGeneral, purpose: .signature)
		) {
			FactorSourceAccess()
		} withDependencies: {
			$0.deviceFactorSourceClient.loadMnemonic = { _ in mnemonicWithPassphrase }
		}

		await store.send(.view(.onFirstTask)) {
			$0.accessMode = .loadingDeviceMnemonic
		}
		await store.receive(.internal(.deviceMnemonicLoaded(factorSource, mnemonicWithPassphrase))) {
			$0.accessMode = .completed
		}
		await store.receive(.delegate(.perform(.device(factorSource, mnemonicWithPassphrase))))
	}

	func testMismatchedStoredMnemonicEntersManualInputWithoutSaving() async {
		let factorSource = PrivateHierarchicalDeterministicFactorSource.testValueZooVote.factorSource
		let mismatchedMnemonic = MnemonicWithPassphrase.testValueAbandonArt
		let store = TestStore(
			initialState: FactorSourceAccess.State(factorSource: factorSource.asGeneral, purpose: .signature)
		) {
			FactorSourceAccess()
		} withDependencies: {
			$0.deviceFactorSourceClient.loadMnemonic = { _ in mismatchedMnemonic }
		}

		await store.send(.view(.onFirstTask)) {
			$0.accessMode = .loadingDeviceMnemonic
		}
		await store.receive(.internal(.deviceMnemonicLoaded(factorSource, mismatchedMnemonic))) {
			$0.accessMode = .manualDeviceMnemonic
			$0.deviceMnemonic = .init(factorSource: factorSource, persistence: .ephemeral)
		}
	}

	func testMissingStoredMnemonicEntersManualInputAndEnablesSaving() async {
		let factorSource = PrivateHierarchicalDeterministicFactorSource.testValueZooVote.factorSource
		let loadCount = LockIsolated(0)
		let store = TestStore(
			initialState: FactorSourceAccess.State(factorSource: factorSource.asGeneral, purpose: .signature)
		) {
			FactorSourceAccess()
		} withDependencies: {
			$0.deviceFactorSourceClient.loadMnemonic = { _ in
				loadCount.withValue { $0 += 1 }
				throw DeviceMnemonicLoadError.missing
			}
		}

		await store.send(.view(.onFirstTask)) {
			$0.accessMode = .loadingDeviceMnemonic
		}
		await store.receive(.internal(.deviceMnemonicUnavailable(factorSource, persistence: .saveAfterValidation))) {
			$0.accessMode = .manualDeviceMnemonic
			$0.deviceMnemonic = .init(factorSource: factorSource, persistence: .saveAfterValidation)
		}
		await store.send(.view(.onFirstTask))
		XCTAssertEqual(loadCount.value, 1)
	}

	func testStorageReadFailureEntersManualInputWithoutSaving() async {
		let factorSource = PrivateHierarchicalDeterministicFactorSource.testValueZooVote.factorSource
		let store = TestStore(
			initialState: FactorSourceAccess.State(factorSource: factorSource.asGeneral, purpose: .signature)
		) {
			FactorSourceAccess()
		} withDependencies: {
			$0.deviceFactorSourceClient.loadMnemonic = { _ in throw DeviceMnemonicLoadError.readFailure }
		}

		await store.send(.view(.onFirstTask)) {
			$0.accessMode = .loadingDeviceMnemonic
		}
		await store.receive(.internal(.deviceMnemonicUnavailable(factorSource, persistence: .ephemeral))) {
			$0.accessMode = .manualDeviceMnemonic
			$0.deviceMnemonic = .init(factorSource: factorSource)
		}
	}

	func testCancelledStoredMnemonicDoesNotEnterManualInput() async {
		let factorSource = PrivateHierarchicalDeterministicFactorSource.testValueZooVote.factorSource
		let store = TestStore(
			initialState: FactorSourceAccess.State(factorSource: factorSource.asGeneral, purpose: .signature)
		) {
			FactorSourceAccess()
		} withDependencies: {
			$0.deviceFactorSourceClient.loadMnemonic = { _ in throw DeviceMnemonicLoadError.cancelledByUser }
		}

		await store.send(.view(.onFirstTask)) {
			$0.accessMode = .loadingDeviceMnemonic
		}
		await store.receive(.internal(.deviceMnemonicLoadCancelled)) {
			$0.accessMode = .automatic
		}
	}

	func testClosingManualEntryClearsSensitiveState() async {
		let factorSource = PrivateHierarchicalDeterministicFactorSource.testValueZooVote.factorSource
		var state = FactorSourceAccess.State(factorSource: factorSource.asGeneral, purpose: .signature)
		state.accessMode = .manualDeviceMnemonic
		state.deviceMnemonic = .init(factorSource: factorSource, persistence: .ephemeral)
		let store = TestStore(initialState: state) {
			FactorSourceAccess()
		}

		await store.send(.view(.closeButtonTapped)) {
			$0.accessMode = .completed
			$0.deviceMnemonic = nil
		}
		await store.receive(.delegate(.cancel))
	}

	func testManualMnemonicMustMatchOriginalFactorSource() async {
		let privateFactorSource = PrivateHierarchicalDeterministicFactorSource.testValueZooVote
		var state = DeviceMnemonicFactorSourceAccess.State(factorSource: privateFactorSource.factorSource)
		state.grid = .init(mnemonic: .testValueAbandonArt)
		let store = TestStore(initialState: state) {
			DeviceMnemonicFactorSourceAccess()
		}

		await store.send(.view(.confirmButtonTapped)) {
			$0.lastSpotCheckFailed = true
		}
	}

	func testMatchingManualMnemonicIsReturned() async {
		let mnemonicWithPassphrase = MnemonicWithPassphrase(
			mnemonic: .testValueZooVote,
			passphrase: "radix"
		)
		let privateFactorSource = PrivateHierarchicalDeterministicFactorSource.testValue(
			mnemonicWithPassphrase: mnemonicWithPassphrase
		)
		var state = DeviceMnemonicFactorSourceAccess.State(factorSource: privateFactorSource.factorSource)
		state.grid = .init(mnemonic: mnemonicWithPassphrase.mnemonic)
		let store = TestStore(initialState: state) {
			DeviceMnemonicFactorSourceAccess()
		}

		await store.send(.view(.passphraseChanged("radix"))) {
			$0.bip39Passphrase = "radix"
		}
		await store.send(.view(.confirmButtonTapped)) {
			$0.isProcessing = true
		}
		await store.receive(.delegate(.perform(mnemonicWithPassphrase)))
	}

	func testMatchingMissingManualMnemonicIsSavedAndReturned() async {
		let privateFactorSource = PrivateHierarchicalDeterministicFactorSource.testValueZooVote
		let mnemonicWithPassphrase = privateFactorSource.mnemonicWithPassphrase
		var state = DeviceMnemonicFactorSourceAccess.State(
			factorSource: privateFactorSource.factorSource,
			persistence: .saveAfterValidation
		)
		state.grid = .init(mnemonic: mnemonicWithPassphrase.mnemonic)
		let savedFactorSource = LockIsolated<PrivateHierarchicalDeterministicFactorSource?>(nil)
		let store = TestStore(initialState: state) {
			DeviceMnemonicFactorSourceAccess()
		} withDependencies: {
			$0.secureStorageClient.saveMnemonicForFactorSource = {
				savedFactorSource.setValue($0)
			}
		}

		await store.send(.view(.confirmButtonTapped)) {
			$0.isProcessing = true
		}
		await store.receive(.delegate(.perform(mnemonicWithPassphrase)))
		XCTAssertEqual(savedFactorSource.value, privateFactorSource)
	}

	func testFailedSaveStillReturnsMatchingManualMnemonic() async {
		struct SaveError: Error {}

		let privateFactorSource = PrivateHierarchicalDeterministicFactorSource.testValueZooVote
		let mnemonicWithPassphrase = privateFactorSource.mnemonicWithPassphrase
		var state = DeviceMnemonicFactorSourceAccess.State(
			factorSource: privateFactorSource.factorSource,
			persistence: .saveAfterValidation
		)
		state.grid = .init(mnemonic: mnemonicWithPassphrase.mnemonic)
		let didScheduleError = LockIsolated(false)
		let store = TestStore(initialState: state) {
			DeviceMnemonicFactorSourceAccess()
		} withDependencies: {
			$0.secureStorageClient.saveMnemonicForFactorSource = { _ in throw SaveError() }
			$0.errorQueue.schedule = { _ in didScheduleError.setValue(true) }
		}

		await store.send(.view(.confirmButtonTapped)) {
			$0.isProcessing = true
		}
		await store.receive(.delegate(.perform(mnemonicWithPassphrase)))
		XCTAssertTrue(didScheduleError.value)
	}
}
