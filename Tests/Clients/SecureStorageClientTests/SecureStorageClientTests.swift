import ClientTestingPrelude
import Cryptography
import LocalAuthenticationClient
@testable import Profile
@testable import SecureStorageClient

// MARK: - SecureStorageClientTests
final class SecureStorageClientTests: TestCase {
	func test__WHEN__factorSource_is_saved__THEN__setDataWithAuth_called_with_icloud_sync_is_disabled() async throws {
		try await doTest(authConfig: .biometricsAndPasscodeSetUp) { sut, factorSource, _ in
			try await sut.saveMnemonicForFactorSource(factorSource)
		} assertKeychainSetItemWithAuthRequest: { request in
			XCTAssertFalse(request.iCloudSyncEnabled)
		}
	}

	func test__WHEN__profile_is_saved__THEN__setDataWithoutAuth_called_with_icloud_sync_is_enabled() async throws {
		try await doTest(authConfig: .biometricsAndPasscodeSetUp) { sut, _, profile in
			try await sut.saveProfileSnapshot(profile)
		} assertKeychainSetItemWithoutAuthRequest: { request in
			XCTAssertTrue(request.iCloudSyncEnabled)
		}
	}

	func test__GIVEN__biometricsAndPasscodeSetUp__WHEN__factorSource_is_saved__THEN__setDataWithAuth_called_with_accessibility_whenPasscodeSetThisDeviceOnly() async throws {
		try await doTest(authConfig: .biometricsAndPasscodeSetUp) { sut, factorSource, _ in
			try await sut.saveMnemonicForFactorSource(factorSource)
		} assertKeychainSetItemWithAuthRequest: { request in
			XCTAssertEqual(request.accessibility, .whenPasscodeSetThisDeviceOnly)
		}
	}

	func test__GIVEN__biometricsAndPasscodeSetUp__WHEN__factorSource_is_saved__THEN__setDataWithAuth_called_with_authPolicy_userPresence() async throws {
		try await doTest(authConfig: .biometricsAndPasscodeSetUp) { sut, factorSource, _ in
			try await sut.saveMnemonicForFactorSource(factorSource)
		} assertKeychainSetItemWithAuthRequest: { request in
			XCTAssertEqual(request.authenticationPolicy, .userPresence)
		}
	}

	func test__GIVEN__passcodeSetUp_no_bio__WHEN__factorSource_is_saved__THEN__setDataWithAuth_called_with_accessibility_whenPasscodeSetThisDeviceOnly() async throws {
		try await doTest(authConfig: .passcodeSetUpButNotBiometrics) { sut, factorSource, _ in
			try await sut.saveMnemonicForFactorSource(factorSource)
		} assertKeychainSetItemWithAuthRequest: { request in
			XCTAssertEqual(request.accessibility, .whenPasscodeSetThisDeviceOnly)
		}
	}

	func test__GIVEN__passcodeSetUp_no_bio__WHEN__factorSource_is_saved__THEN__setDataWithAuth_called_with_authPolicy_userPresence() async throws {
		try await doTest(authConfig: .passcodeSetUpButNotBiometrics) { sut, factorSource, _ in
			try await sut.saveMnemonicForFactorSource(factorSource)
		} assertKeychainSetItemWithAuthRequest: { request in
			XCTAssertEqual(request.authenticationPolicy, .userPresence)
		}
	}

	func test__GIVEN__no_passcode__WHEN__factorSource_is_saved__THEN__an_error_is_thrown() async throws {
		try await doTest(authConfig: .neitherBiometricsNorPasscodeSetUp) { sut, factorSource, _ in
			do {
				try await sut.saveMnemonicForFactorSource(factorSource)
				XCTFail("expected failure")
			} catch {
				XCTAssertEqual(error as? SecureStorageError, SecureStorageError.passcodeNotSet)
			}
		} assertKeychainSetItemWithoutAuthRequest: { request in
			XCTAssertEqual(request.accessibility, .whenUnlocked)
		}
	}

	func test__GIVEN__biometricsAndPasscodeSetUp__WHEN__profile_is_saved__THEN__setDataWithoutAuth_called_with_accessibility_whenUnlocked() async throws {
		try await doTest(authConfig: .biometricsAndPasscodeSetUp) { sut, _, profile in
			try await sut.saveProfileSnapshot(profile)
		} assertKeychainSetItemWithoutAuthRequest: { request in
			XCTAssertEqual(request.accessibility, .whenUnlocked)
		}
	}
}

private extension SecureStorageClientTests {
	func doTest(
		authConfig: LocalAuthenticationConfig,
		operation: (SecureStorageClient, PrivateHDFactorSource, ProfileSnapshot) async throws -> Void,
		assertKeychainSetItemWithoutAuthRequest: (@Sendable (KeychainClient.SetItemWithoutAuthRequest) throws -> Void)? = nil,
		assertKeychainSetItemWithAuthRequest: (@Sendable (KeychainClient.SetItemWithAuthRequest) throws -> Void)? = nil
	) async throws {
		try await withDependencies {
			$0.uuid = .incrementing
			$0.keychainClient.setDataWithoutAuthForKey = { request in
				if let assertKeychainSetItemWithoutAuthRequest {
					try assertKeychainSetItemWithoutAuthRequest(request)
				} else {
					XCTFail("Did not expect `setDataWithoutAuthForKey` to be called")
				}
			}
			$0.keychainClient.setDataWithAuthForKey = { request in
				if let assertKeychainSetItemWithAuthRequest {
					try assertKeychainSetItemWithAuthRequest(request)
				} else {
					XCTFail("Did not expect `setDataWithAuthForKey` to be called")
				}
			}
			$0.localAuthenticationClient.queryConfig = { authConfig }
			$0.date = .constant(.init(timeIntervalSince1970: 0))
		} operation: {
			let mnemonic = try Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
			let passphrase = ""
			let mnemonicWithPassphrase = MnemonicWithPassphrase(mnemonic: mnemonic, passphrase: passphrase)
			let factorSource = try FactorSource.babylon(mnemonic: mnemonicWithPassphrase.mnemonic, bip39Passphrase: passphrase)

			let privateHDFactorSource = try PrivateHDFactorSource(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				hdOnDeviceFactorSource: factorSource
			)

			let sut = SecureStorageClient.liveValue
			let profile = Profile(factorSource: factorSource.factorSource)
			try await operation(sut, privateHDFactorSource, profile.snapshot())
		}
	}
}
