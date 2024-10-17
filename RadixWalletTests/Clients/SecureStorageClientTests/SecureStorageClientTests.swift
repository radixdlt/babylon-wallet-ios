@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - SecureStorageClientTests
final class SecureStorageClientTests: TestCase {
	// THIS TEST IS NEVER EVER EVER EVER ALLOWED TO FAIL!!! If it does, user might
	// lose their funds!!!!!!
	func test_assert_key_for_mnemonic_is_unchanged() async throws {
		try await doTest(authConfig: .biometricsAndPasscodeSetUp) { sut, factorSource, _ in
			try await sut.saveMnemonicForFactorSource(factorSource)
		} assertKeychainSetItemWithAuthRequest: { _, key, _ in
			guard key == "device:09a501e4fafc7389202a82a3237a405ed191cdb8a4010124ff8e2c9259af1327" else {
				fatalError("CRITICAL UNIT TEST FAILURE - LOSS OF FUNDS POSSIBLE.")
			}
		}
	}

	func test__WHEN__factorSource_is_saved__THEN__setDataWithAuth_called_with_icloud_sync_is_disabled() async throws {
		try await doTest(authConfig: .biometricsAndPasscodeSetUp) { sut, factorSource, _ in
			try await sut.saveMnemonicForFactorSource(factorSource)
		} assertKeychainSetItemWithAuthRequest: { _, _, attributes in
			XCTAssertFalse(attributes.iCloudSyncEnabled)
		}
	}

	func test__WHEN__profile_is_saved__THEN__setDataWithoutAuth_called_with_icloud_sync_is_disabled() async throws {
		try await doTest(authConfig: .biometricsAndPasscodeSetUp) { sut, _, profile in
			try sut.saveProfileSnapshotData(profile.id, profile.jsonData())
		} assertKeychainSetItemWithoutAuthRequest: { _, _, attributes in
			XCTAssertFalse(attributes.iCloudSyncEnabled)
		}
	}

	func test__GIVEN__biometricsAndPasscodeSetUp__WHEN__factorSource_is_saved__THEN__setDataWithAuth_called_with_accessibility_whenPasscodeSetThisDeviceOnly() async throws {
		try await doTest(authConfig: .biometricsAndPasscodeSetUp) { sut, factorSource, _ in
			try await sut.saveMnemonicForFactorSource(factorSource)
		} assertKeychainSetItemWithAuthRequest: { _, _, attributes in
			XCTAssertEqual(attributes.accessibility, .whenPasscodeSetThisDeviceOnly)
		}
	}

	func test__GIVEN__biometricsAndPasscodeSetUp__WHEN__factorSource_is_saved__THEN__setDataWithAuth_called_with_authPolicy_userPresence() async throws {
		try await doTest(authConfig: .biometricsAndPasscodeSetUp) { sut, factorSource, _ in
			try await sut.saveMnemonicForFactorSource(factorSource)
		} assertKeychainSetItemWithAuthRequest: { _, _, attributes in
			XCTAssertEqual(attributes.authenticationPolicy, .userPresence)
		}
	}

	func test__GIVEN__passcodeSetUp_no_bio__WHEN__factorSource_is_saved__THEN__setDataWithAuth_called_with_accessibility_whenPasscodeSetThisDeviceOnly() async throws {
		try await doTest(authConfig: .passcodeSetUpButNotBiometrics) { sut, factorSource, _ in
			try await sut.saveMnemonicForFactorSource(factorSource)
		} assertKeychainSetItemWithAuthRequest: { _, _, attributes in
			XCTAssertEqual(attributes.accessibility, .whenPasscodeSetThisDeviceOnly)
		}
	}

	func test__GIVEN__passcodeSetUp_no_bio__WHEN__factorSource_is_saved__THEN__setDataWithAuth_called_with_authPolicy_userPresence() async throws {
		try await doTest(authConfig: .passcodeSetUpButNotBiometrics) { sut, factorSource, _ in
			try await sut.saveMnemonicForFactorSource(factorSource)
		} assertKeychainSetItemWithAuthRequest: { _, _, attributes in
			XCTAssertEqual(attributes.authenticationPolicy, .userPresence)
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
		} assertKeychainSetItemWithoutAuthRequest: { _, _, attributes in
			XCTAssertEqual(attributes.accessibility, .whenUnlocked)
		}
	}

	func test__GIVEN__biometricsAndPasscodeSetUp__WHEN__profile_is_saved__THEN__setDataWithoutAuth_called_with_accessibility_whenUnlocked() async throws {
		try await doTest(authConfig: .biometricsAndPasscodeSetUp) { sut, _, profile in
			try sut.saveProfileSnapshotData(profile.id, profile.jsonData())
		} assertKeychainSetItemWithoutAuthRequest: { _, _, attributes in
			XCTAssertEqual(attributes.accessibility, .whenUnlocked)
		}
	}
}

private extension SecureStorageClientTests {
	func doTest(
		authConfig: LocalAuthenticationConfig,
		operation: (SecureStorageClient, PrivateHierarchicalDeterministicFactorSource, Profile) async throws -> Void,
		assertKeychainSetItemWithoutAuthRequest: (@Sendable (Data, KeychainClient.Key, KeychainClient.AttributesWithoutAuth) throws -> Void)? = nil,
		assertKeychainSetItemWithAuthRequest: (@Sendable (Data, KeychainClient.Key, KeychainClient.AttributesWithAuth) throws -> Void)? = nil
	) async throws {
		try await withDependencies {
			$0.uuid = .incrementing
			$0.keychainClient._setDataWithoutAuthForKey = { data, key, attributes in
				if let assertKeychainSetItemWithoutAuthRequest {
					try assertKeychainSetItemWithoutAuthRequest(data, key, attributes)
				} else {
					XCTFail("Did not expect `setDataWithoutAuthForKey` to be called")
				}
			}
			$0.keychainClient._setDataWithAuthForKey = { data, key, attributes in
				if let assertKeychainSetItemWithAuthRequest {
					try assertKeychainSetItemWithAuthRequest(data, key, attributes)
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
			let factorSource = try DeviceFactorSource.babylon(
				mnemonicWithPassphrase: mnemonicWithPassphrase, isMain: true,
				hostInfo: .sample
			)

			let privateHDFactorSource = try PrivateHierarchicalDeterministicFactorSource(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				factorSource: factorSource
			)

			let sut = SecureStorageClient.liveValue
			let profile = Profile(
				header: header,
				deviceFactorSource: factorSource
			)
			try await operation(sut, privateHDFactorSource, profile)
		}
	}
}

private let device: DeviceInfo = .sample

// private let snapshotHeader = Header(
//	creatingDevice: device,
//	lastUsedOnDevice: device,
//	id: stableUUID,
//	lastModified: stableDate,
//	contentHint: .init(
//		numberOfAccountsOnAllNetworksInTotal: 6,
//		numberOfPersonasOnAllNetworksInTotal: 3,
//		numberOfNetworks: 2
//	),
//	snapshotVersion: .minimum
// )
private var header: Header {
	var header = Header.sample
	header.contentHint.numberOfNetworks = 2
	header.contentHint.numberOfAccountsOnAllNetworksInTotal = 6
	header.contentHint.numberOfPersonasOnAllNetworksInTotal = 3
	return header
}
