import DependenciesAdditions
@testable import Radix_Wallet_Dev
import XCTest

// swiftformat:disable redundantInit

extension DependencyValues {
	private mutating func _profile(_ profile: Profile?) {
		secureStorageClient.loadProfile = { _ in
			profile
		}
		userDefaultsClient.stringForKey = {
			if $0 == .activeProfileID {
				profile?.header.id.uuidString
			} else { String?.none }
		}
		mnemonicClient.generate = { _, _ in .testValue }
	}

	mutating func savedProfile(_ savedProfile: Profile) {
		_profile(savedProfile)
	}

	mutating func noProfile() {
		_profile(nil)
	}

	mutating func noDeviceInfo() {
		secureStorageClient.loadDeviceInfo = { nil }
	}
}

// MARK: - ProfileStoreNewProfileTests
final class ProfileStoreNewProfileTests: TestCase {
	func test__GIVEN__no_deviceInfo__WHEN__init__THEN__deprecatedLoadDeviceID_is_called() {
		let deprecatedLoadDeviceID_is_called = expectation(description: "deprecatedLoadDeviceID is called")
		withTestClients {
			// GIVEN no device info
			$0.noDeviceInfo()
			then(&$0)
		} operation: {
			// WHEN ProfileStore.init()
			ProfileStore.init()
		}

		func then(_ d: inout DependencyValues) {
			d.secureStorageClient.deprecatedLoadDeviceID = {
				// THEN deprecatedLoadDeviceID is called
				deprecatedLoadDeviceID_is_called.fulfill()
				return UUID?.none
			}
		}
		wait(for: [deprecatedLoadDeviceID_is_called])
	}

	func test__GIVEN__no_deviceInfo__WHEN__deprecatedLoadDeviceID_returns_x__THEN__deleteDeprecatedDeviceID_is_called() async throws {
		let deleteDeprecatedDeviceID_is_called = expectation(description: "deleteDeprecatedDeviceID is called")
		withTestClients {
			// GIVEN no device info
			$0.noDeviceInfo()
			$0.secureStorageClient.deprecatedLoadDeviceID = { 0xDEAD }
			then(&$0)
		} operation: {
			// WHEN ProfileStore.init()
			ProfileStore.init()
		}

		func then(_ d: inout DependencyValues) {
			d.secureStorageClient.deleteDeprecatedDeviceID = {
				// THEN deleteDeprecatedDeviceID is called
				deleteDeprecatedDeviceID_is_called.fulfill()
			}
		}
		await waitForExpectations()
	}

	func test__GIVEN__no_deviceInfo__WHEN__deprecatedLoadDeviceID_returns_x__THEN__deleteDeprecatedDeviceID_is_not_called_if_failed_to_save_migrated_deviceInfo() async {
		let deleteDeprecatedDeviceID_is_NOT_called = expectation(description: "deleteDeprecatedDeviceID is NOT called")
		deleteDeprecatedDeviceID_is_NOT_called.isInverted = true // We expected to NOT be called.

		withTestClients {
			// GIVEN no device info
			$0.noDeviceInfo()
			$0.secureStorageClient.deprecatedLoadDeviceID = { 0xDEAD }
			then(&$0)
		} operation: {
			// WHEN ProfileStore.init()
			ProfileStore.init()
		}

		func then(_ d: inout DependencyValues) {
			d.secureStorageClient.deleteDeprecatedDeviceID = {
				// THEN deleteDeprecatedDeviceID is NOT called if...
				deleteDeprecatedDeviceID_is_NOT_called.fulfill()
			}
			// ... if failed to save migrated deviceInfo
			d.secureStorageClient.saveDeviceInfo = { _ in throw NoopError() }
		}

		await waitForExpectations()
	}

	func test__GIVEN_a_saved_deviceInfo__WHEN__init__THEN__deprecatedLoadDeviceID_is_not_called() async {
		let deprecatedLoadDeviceID_is_NOT_called = expectation(description: "deprecatedLoadDeviceID is NOT called")
		deprecatedLoadDeviceID_is_NOT_called.isInverted = true // We expected to NOT be called.

		withTestClients {
			// GIVEN a saved_ device info
			$0.secureStorageClient.loadDeviceInfo = { .testValue }
			then(&$0)
		} operation: {
			// WHEN ProfileStore.init()
			ProfileStore.init()
		}

		func then(_ d: inout DependencyValues) {
			d.secureStorageClient.deprecatedLoadDeviceID = {
				// THEN deprecatedLoadDeviceID is not called
				deprecatedLoadDeviceID_is_NOT_called.fulfill()
				return nil
			}
		}

		await waitForExpectations()
	}

	func test__GIVEN__no_deviceInfo__WHEN__deprecatedLoadDeviceID_returns_x__THEN__x_is_migrated_to_DeviceInfo_and_saved() {
		let x: DeviceID = 0xDEAD
		withTestClients {
			// GIVEN no device info
			$0.noDeviceInfo()
			$0.secureStorageClient.deprecatedLoadDeviceID = { x }
			then(&$0)
		} operation: {
			// WHEN ProfileStore.init()
			ProfileStore.init()
		}

		func then(_ d: inout DependencyValues) {
			d.secureStorageClient.saveDeviceInfo = {
				// THEN x is migrated to DeviceInfo and saved
				XCTAssertNoDifference($0.id, x)
			}
		}
	}

	func test__GIVEN__no_deviceInfo__WHEN__deprecatedLoadDeviceID_returns_x__THEN__x_is_migrated_to_DeviceInfo_and_used() async throws {
		try await withTimeLimit {
			let x: DeviceID = 0xDEAD

			let profile = await withTestClients {
				// GIVEN no device info
				$0.noDeviceInfo()
				$0.secureStorageClient.deprecatedLoadDeviceID = { x }
			} operation: {
				// WHEN ProfileStore.init()
				await ProfileStore.init().profile
			}

			// THEN x is migrated to DeviceInfo and used
			XCTAssertNoDifference(profile.header.creatingDevice.id, x)
		}
	}

	func test__GIVEN__no_profile__WHEN__init__THEN__new_profile_without_network_is_used() async throws {
		try await withTimeLimit {
			let newProfile = await withTestClients {
				// GIVEN no profile
				$0.noProfile()
			} operation: {
				// WHEN ProfileStore.init()
				await ProfileStore.init().profile
			}

			// THEN new profile without network is used
			XCTAssertNoDifference(newProfile.networks.count, 0)
		}
	}

	func test__GIVEN__no_profile__WHEN__init__THEN__24_word_mnemonic_is_generated() throws {
		withTestClients {
			// GIVEN no profile
			$0.noProfile()
			then(&$0)
		} operation: {
			// WHEN ProfileStore.init()
			ProfileStore.init()
		}

		func then(_ d: inout DependencyValues) {
			d.mnemonicClient.generate = { wordCount, _ in
				// THEN 24 word mnemonic is generated
				XCTAssertNoDifference(wordCount, .twentyFour)
				return try Mnemonic(wordCount: wordCount, language: .english)
			}
		}
	}

	func test__GIVEN__no_profile__WHEN__init__THEN__profile_uses_newly_generated_DeviceFactorSource() async throws {
		try await withTimeLimit {
			let profile = await withTestClients {
				// GIVEN no profile
				$0.noProfile()

				$0.mnemonicClient.generate = { _, _ in
					"zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong"
				}
			} operation: {
				// WHEN ProfileStore.init()
				await ProfileStore.init().profile
			}

			XCTAssertNoDifference(
				profile.factorSources.first.id.description,
				// THEN profile uses newly generated DeviceFactorSource
				"device:09a501e4fafc7389202a82a3237a405ed191cdb8a4010124ff8e2c9259af1327"
			)
		}
	}

	func test__GIVEN__no_profile__WHEN__init__THEN__profile_lastUsedOnDevice_equals_creatingDevice() async throws {
		try await withTimeLimit {
			let profile = await withTestClients {
				// GIVEN no profile
				$0.noProfile()
			} operation: {
				// WHEN ProfileStore.init()
				await ProfileStore.init().profile
			}

			// THEN profile lastUsedOnDevice == creatingDevice
			XCTAssertNoDifference(
				profile.header.lastUsedOnDevice,
				profile.header.creatingDevice
			)
		}
	}

	func test__GIVEN__no_profile__WHEN__init__THEN__profile_id_not_equals_creatingDeviceID() async throws {
		try await withTimeLimit {
			let profile = await withTestClients {
				// GIVEN no profile
				$0.noProfile()
			} operation: {
				// WHEN ProfileStore.init()
				await ProfileStore.init().profile
			}

			// THEN profile.id != profile.creatingDevice.id
			XCTAssertNotEqual(
				profile.header.id,
				profile.header.creatingDevice.id
			)
		}
	}

	func test__GIVEN__no_profile__WHEN__init__THEN__newly_generated_DeviceFactorSource_is_persisted() throws {
		withTestClients {
			// GIVEN no profile
			$0.noProfile()

			$0.mnemonicClient.generate = { _, _ in
				"zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong"
			}

			then(&$0)
		} operation: {
			// WHEN ProfileStore.init()
			ProfileStore.init()
		}

		func then(_ d: inout DependencyValues) {
			d.secureStorageClient.saveMnemonicForFactorSource = {
				XCTAssertNoDifference(
					$0.factorSource.id.description,
					// THEN profile uses newly generated DeviceFactorSource
					"device:09a501e4fafc7389202a82a3237a405ed191cdb8a4010124ff8e2c9259af1327"
				)
			}
		}
	}

	func test__GIVEN__no_profile__WHEN__init__THEN__newly_generated_mnemonic_is_persisted() throws {
		let mnemonic: Mnemonic = "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong"
		withTestClients {
			// GIVEN no profile
			$0.noProfile()

			$0.mnemonicClient.generate = { _, _ in
				mnemonic
			}

			then(&$0)
		} operation: {
			// WHEN ProfileStore.init()
			ProfileStore.init()
		}

		func then(_ d: inout DependencyValues) {
			d.secureStorageClient.saveMnemonicForFactorSource = {
				XCTAssertNoDifference(
					$0.mnemonicWithPassphrase.mnemonic,
					// THEN profile uses newly generated mnemonic
					mnemonic
				)
			}
		}
	}

	func test__GIVEN__no_profile__WHEN__init__THEN__newly_generated_mnemonic_is_used_with_empty_passphrase() throws {
		withTestClients {
			// GIVEN no profile
			$0.noProfile()

			$0.mnemonicClient.generate = { _, _ in
				"zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong"
			}

			then(&$0)
		} operation: {
			// WHEN ProfileStore.init()
			ProfileStore.init()
		}

		func then(_ d: inout DependencyValues) {
			d.secureStorageClient.saveMnemonicForFactorSource = {
				XCTAssertTrue(
					// THEN generated mnemonic is used with empty passphrase
					$0.mnemonicWithPassphrase.passphrase.isEmpty
				)
			}
		}
	}
}

// MARK: - ProfileStoreExstingProfileTests
final class ProfileStoreExstingProfileTests: TestCase {
	func test__GIVEN__saved_profile__WHEN__init__THEN__saved_profile_is_used() async throws {
		try await withTimeLimit {
			// GIVEN saved profile
			let saved = Profile.withOneAccount

			let used = await withTestClients {
				$0.savedProfile(saved)
			} operation: {
				// WHEN ProfileStore.init()
				await ProfileStore.init().profile
			}

			// THEN saved profile is used.
			XCTAssertNoDifference(saved, used)
		}
	}
}

extension PrivateHDFactorSource {
	static let testValue: Self = withDependencies {
		$0.date = .constant(Date(timeIntervalSince1970: 0))
	} operation: {
		Self.testValue(name: deviceName, model: deviceModel)
	}
}

private let deviceName: String = "iPhone"
private let deviceModel: DeviceFactorSource.Hint.Model = "iPhone"
private let expectedDeviceDescription = DeviceInfo.deviceDescription(
	name: deviceName,
	model: deviceModel.rawValue
)

extension ProfileStore {
	func update(profile: Profile) throws {
		try _update(profile: profile)
	}
}

extension Mnemonic {
	static let testValue: Self = "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong"
}
