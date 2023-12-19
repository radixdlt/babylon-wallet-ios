import DependenciesAdditions
@testable import Radix_Wallet_Dev
import XCTest

// swiftformat:disable redundantInit

extension DependencyValues {
	private mutating func _profile(
		_ profile: Profile?,
		userDefaults userDefaultsValue: UserDefaults.Dependency = .ephemeral()
	) {
		if let profile {
			secureStorageClient.loadProfile = { key in
				precondition(key == profile.header.id)
				return profile
			}
			secureStorageClient.loadProfileSnapshot = { key in
				precondition(key == profile.header.id)
				return profile.snapshot()
			}
			secureStorageClient.loadProfileSnapshotData = { key in
				precondition(key == profile.header.id)

				return try! JSONEncoder.iso8601.encode(profile.snapshot())
			}
		} else {
			secureStorageClient.loadProfile = { _ in
				nil
			}
			secureStorageClient.loadProfileSnapshot = { _ in
				nil
			}
			secureStorageClient.loadProfileSnapshotData = { _ in
				nil
			}
		}
		userDefaultsValue.set(string: profile?.header.id.uuidString, key: .activeProfileID)
		self.userDefaults = userDefaultsValue
		mnemonicClient.generate = { _, _ in .testValue }
	}

	mutating func savedProfile(
		_ savedProfile: Profile,
		userDefaults: UserDefaults.Dependency = .ephemeral()
	) {
		_profile(savedProfile, userDefaults: userDefaults)
	}

	mutating func noProfile(
		userDefaults: UserDefaults.Dependency = .ephemeral()
	) {
		_profile(nil, userDefaults: userDefaults)
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
		let userDefaults = UserDefaults.Dependency.ephemeral()
		withTestClients(userDefaults: userDefaults) {
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

		await nearFutureFulfillment(of: deleteDeprecatedDeviceID_is_called)
	}

	func test__GIVEN__no_deviceInfo__WHEN__deprecatedLoadDeviceID_returns_x__THEN__deleteDeprecatedDeviceID_is_not_called_if_failed_to_save_migrated_deviceInfo() async throws {
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

		await nearFutureFulfillment(of: deleteDeprecatedDeviceID_is_NOT_called)
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

		await nearFutureFulfillment(of: deprecatedLoadDeviceID_is_NOT_called)
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
			XCTAssertTrue(newProfile.networks.isEmpty)
		}
	}

	func test__GIVEN__no_profile__WHEN__init__THEN__new_profile_with_main_BDFS_is_created() async throws {
		try await withTimeLimit {
			let newProfile = await withTestClients {
				// GIVEN no profile
				$0.noProfile()
			} operation: {
				// WHEN ProfileStore.init()
				await ProfileStore.init().profile
			}

			let deviceFS = try newProfile.factorSources[0].extract(as: DeviceFactorSource.self)
			XCTAssertTrue(deviceFS.isExplicitMainBDFS)
		}
	}

	func test__GIVEN__no_profile__WHEN__import_profile__THEN__imported_profile_is_used() async throws {
		try await withTimeLimit(.normal) {
			let usedProfile = try await withTestClients {
				// GIVEN no profile
				$0.noProfile()
			} operation: {
				let sut = ProfileStore()
				// WHEN import profile
				try await sut.importProfile(Profile.withOneAccountsDeviceInfo_ABBA_mnemonic_ABANDON_ART)
				return await sut.profile
			}

			// THEN imported profile is used
			XCTAssertNoDifference(usedProfile, Profile.withOneAccountsDeviceInfo_ABBA_mnemonic_ABANDON_ART)
		}
	}

	func test__GIVEN__no_profile__WHEN__import_profile_current_network_not_main__THEN__mainnet_is_set_to_current() async throws {
		try await withTimeLimit(.normal) {
			let usedProfile = try await withTestClients {
				// GIVEN no profile
				$0.noProfile()
			} operation: {
				let sut = ProfileStore()
				// WHEN import profile
				var profileToImport = Profile.withOneAccountsDeviceInfo_ABBA_mnemonic_ABANDON_ART
				try profileToImport.addAccount(Profile.Network.Account.makeTestValue(name: "stoke", networkID: .stokenet))
				try profileToImport.changeGateway(to: .stokenet)
				try await sut.importProfile(profileToImport)
				return await sut.profile
			}

			// THEN imported profile is used
			XCTAssertNoDifference(usedProfile.network?.networkID, .mainnet)
		}
	}

	func test__GIVEN__no_profile__WHEN__import_profile_from_icloud__THEN__imported_profile_is_used() async throws {
		let profileSnapshotInIcloud = Profile.withOneAccountsDeviceInfo_ABBA_mnemonic_ABANDON_ART
		try await withTimeLimit {
			let usedProfile = try await withTestClients {
				// GIVEN no profile
				$0.noProfile()
				$0.secureStorageClient.loadProfileSnapshot = { headerId in
					if headerId == profileSnapshotInIcloud.header.id {
						profileSnapshotInIcloud.snapshot()
					} else { nil }
				}
			} operation: {
				let sut = ProfileStore()
				// WHEN import profile
				try await sut.importCloudProfileSnapshot(profileSnapshotInIcloud.header)
				return await sut.profile
			}

			// THEN imported profile is used
			XCTAssertNoDifference(usedProfile, profileSnapshotInIcloud)
		}
	}

	func test__GIVEN__no_profile__WHEN__import_profile_from_icloud_not_exists__THEN__error_is_thrown() async throws {
		let icloudHeader: ProfileSnapshot.Header = .testValueProfileID_DEAD_deviceID_ABBA
		try await withTimeLimit {
			let assertionFailureIsCalled = self.expectation(description: "assertionFailure is called")
			try await withTestClients {
				// GIVEN no profile
				$0.noProfile()
				$0.secureStorageClient.loadProfileSnapshot = { headerId in
					XCTAssertEqual(headerId, icloudHeader.id)
					return nil
				}
				$0.assertionFailure = AssertionFailureAction.init(action: { _, _, _ in
					// THEN identity is checked
					assertionFailureIsCalled.fulfill()
				})
			} operation: {
				let sut = ProfileStore()
				// WHEN import profile
				do {
					try await sut.importCloudProfileSnapshot(icloudHeader)
					return XCTFail("expected error")
				} catch {}
			}

			await self.nearFutureFulfillment(of: assertionFailureIsCalled)
		}
	}

	func test__GIVEN__no_profile__WHEN__import_profile__THEN__ownership_has_changed() async throws {
		let deviceInfo = DeviceInfo.testValueABBA
		try await withTimeLimit {
			let usedProfile = try await withTestClients {
				// GIVEN no profile
				$0.noProfile()
				$0.secureStorageClient.loadDeviceInfo = { deviceInfo }
			} operation: {
				let sut = ProfileStore()
				// WHEN import profile
				try await sut.importProfile(Profile.withOneAccountsDeviceInfo_BEEF_mnemonic_ABANDON_ART)
				return await sut.profile
			}

			// THEN imported profile is used
			XCTAssertNoDifference(
				usedProfile.header.lastUsedOnDevice,
				deviceInfo
			)
		}
	}

	func test__GIVEN__no_profile__WHEN__import_profile__THEN__ephemeral_profile_is_deleted() async throws {
		try await withTimeLimit {
			let ephemeralProfileIsDeleted = self.expectation(description: "ephemeral profile is deleted")
			let idOfDeleted = LockIsolated<Profile.ID?>(nil)
			let ephemeralProfile = try await withTestClients {
				// GIVEN no profile
				$0.noProfile()
				then(&$0)
			} operation: {
				let sut = ProfileStore()
				let ephemeralProfile = await sut.profile
				// WHEN import profile
				try await sut.importProfile(Profile.withOneAccountsDeviceInfo_ABBA_mnemonic_ABANDON_ART)
				return ephemeralProfile
			}

			// THEN ephemeral profile is deleted
			func then(_ d: inout DependencyValues) {
				d.secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs = { id, _ in
					idOfDeleted.setValue(id)
					ephemeralProfileIsDeleted.fulfill()
				}
			}

			await self.nearFutureFulfillment(of: ephemeralProfileIsDeleted)
			idOfDeleted.withValue { deletedID in
				XCTAssertNoDifference(deletedID, ephemeralProfile.id)
			}
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

	func test__GIVEN__no_profile_but_deviceInfo_WHEN__init__THEN__profile_creatingDevice_equals_deviceInfo() async throws {
		try await withTimeLimit {
			let deviceInfo = DeviceInfo.testValue
			let profile = await withTestClients {
				// GIVEN no profile
				$0.noProfile() // but deviceInfo
				$0.secureStorageClient.loadDeviceInfo = { deviceInfo }
			} operation: {
				// WHEN ProfileStore.init()
				await ProfileStore.init().profile
			}

			// THEN profile creatingDevice == deviceInfo
			XCTAssertNoDifference(
				profile.header.creatingDevice,
				deviceInfo
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

	func test__GIVEN__no_profile__WHEN__finishOnboarding__THEN__iphone__model_is_updated_in_profile_and_keychain() async throws {
		try await withTimeLimit {
			let savedSnapshot = LockIsolated<ProfileSnapshot?>(nil)

			let inMemory = try await withTestClients {
				// GIVEN no profile
				$0.noProfile()
				$0.device.$model = { "marco" }
				$0.device.$name = { "polo" }
				then(&$0)
			} operation: {
				// WHEN finishedOnboarding
				let sut = ProfileStore()
				try await sut.updating {
					try $0.addAccount(Profile.Network.Account.testValue)
				}
				await sut.finishedOnboarding()
				return await sut.profile
			}

			func then(_ d: inout DependencyValues) {
				d.secureStorageClient.saveProfileSnapshot = {
					savedSnapshot.setValue($0)
				}
			}

			func assert(_ header: ProfileSnapshot.Header?) {
				let expected = "marco (polo)"
				XCTAssertNoDifference(header?.creatingDevice.description, expected)
				XCTAssertNoDifference(header?.lastUsedOnDevice.description, expected)
			}

			// THEN iphone model is updated in Profile ...
			assert(inMemory.header)
			savedSnapshot.withValue { inKeychain in
				// ... and in keychain
				assert(inKeychain?.header)
			}
		}
	}
}

// MARK: - ProfileStoreExistingProfileTests
final class ProfileStoreExistingProfileTests: TestCase {
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

	func test__GIVEN__saved_empty_profile__WHEN__passcode_removed__THEN__new_profile_is_used() async throws {
		try await withTimeLimit {
			let mnemonicGotDeleted = self.expectation(description: "Mnemonic got deleted")
			// GIVEN saved profile
			let savedEmptyProfile = ProfileBuilder().bdfs().build(allowEmpty: true)
			let firstBDFS = savedEmptyProfile.factorSources.babylonDevice

			let used = await withTestClients {
				$0.secureStorageClient.containsMnemonicIdentifiedByFactorSourceID = { factorSourceID in
					// WHEN passcode remove (mnemonic deleted)
					if factorSourceID == firstBDFS.id {
						mnemonicGotDeleted.fulfill()
						return false
					}
					return true
				}
				$0.savedProfile(savedEmptyProfile)
			} operation: {
				await ProfileStore.init().profile
			}

			await self.nearFutureFulfillment(of: mnemonicGotDeleted)

			// THEN a new profile is used
			XCTAssertNotEqual(savedEmptyProfile, used)
		}
	}

	func test__GIVEN__profile_with_owner_X__WHEN__deprecatedLoadDeviceID_returns_X__THEN__x_is_migrated_to_DeviceInfo_and_saved() async throws {
		try await withTimeLimit {
			let savedProfile = Profile.withOneAccount
			let x = savedProfile.header.lastUsedOnDevice.id
			let used = await withTestClients {
				// GIVEN no device info
				$0.savedProfile(savedProfile)
				$0.secureStorageClient.loadDeviceInfo = { nil }
				when(&$0)
				then(&$0)
			} operation: {
				await ProfileStore().profile
			}

			func when(_ d: inout DependencyValues) {
				d.secureStorageClient.deprecatedLoadDeviceID = { x }
			}

			func then(_ d: inout DependencyValues) {
				d.secureStorageClient.saveDeviceInfo = {
					// THEN x is migrated to DeviceInfo and saved
					XCTAssertNoDifference($0.id, x)
				}
			}
		}
	}

	func test__GIVEN__saved_profile__WHEN__we_update_profile__THEN__ownership_is_checked_by_loading_profile_from_keychain() async throws {
		try await withTimeLimit {
			// GIVEN saved profile
			let saved = Profile.withOneAccount

			let profileHasBeenUpdated = LockIsolated<Bool>(false)
			let profile_is_loaded_from_keychain = self.expectation(description: "profile is loaded from keychain")

			try await withTestClients {
				$0.savedProfile(saved)
				then(&$0)
			} operation: {
				let sut = ProfileStore()
				// WHEN we update profile
				try await sut.updating {
					$0.header.lastModified = Date()
					profileHasBeenUpdated.setValue(true)
				}
			}

			func then(_ d: inout DependencyValues) {
				d.secureStorageClient.loadProfileSnapshot = { id in
					profileHasBeenUpdated.withValue { hasBeenUpdated in
						if hasBeenUpdated {
							XCTAssertNoDifference(id, saved.id)
							// THEN ownership is checked by loading profile from keychain
							profile_is_loaded_from_keychain.fulfill()
						}
					}
					return saved.snapshot()
				}
			}

			await self.nearFutureFulfillment(of: profile_is_loaded_from_keychain)
		}
	}

	func test__GIVEN__saved_profile_P__WHEN__we_update_P_changing_its_identity__THEN__identity_is_checked() async throws {
		try await withTimeLimit(.normal) {
			// GIVEN saved profile
			let P = Profile.withOneAccountsDeviceInfo_ABBA_mnemonic_ZOO_VOTE
			let Q = Profile.withOneAccountsDeviceInfo_BEEF_mnemonic_ABANDON_ART
			XCTAssertNotEqual(P.header, Q.header)

			let identityCheckFails = self.expectation(description: "identity check fails")

			try await withTestClients {
				$0.savedProfile(P)
				then(&$0)
			} operation: {
				let sut = ProfileStore()
				do {
					try await sut.updating {
						// WHEN we update profile changing_its_identity
						$0.header = Q.header // swap headers... emulating some ultra weird state.
					}
					return XCTFail("We expected to throw")
				} catch {}
			}

			func then(_ d: inout DependencyValues) {
				d.assertionFailure = AssertionFailureAction.init(action: { _, _, _ in
					// THEN identity is checked
					identityCheckFails.fulfill()
				})
			}

			await self.nearFutureFulfillment(of: identityCheckFails)
		}
	}

	func test__GIVEN__saved_profile_mismatch_deviceID__WHEN__claimAndContinueUseOnThisPhone__THEN__profile_uses_claimed_device() async throws {
		try await doTestMismatch(
			savedProfile: Profile.withOneAccount,
			action: .claimAndContinueUseOnThisPhone
		) { claimed in
			// THEN profile uses claimed device
			XCTAssertNoDifference(
				claimed.header.lastUsedOnDevice.id,
				DeviceInfo.testValueBEEF.id
			)
		}
	}

	func test__GIVEN__saved_profile_mismatch_deviceID__WHEN__deleteProfile__THEN__profile_got_deleted() async throws {
		let uuidOfNewProfile = UUID()
		let savedProfile = Profile.withOneAccount
		let userDefaults = UserDefaults.Dependency.ephemeral()
		try await doTestMismatch(
			savedProfile: savedProfile,
			userDefaults: userDefaults,
			action: .deleteProfileFromThisPhone,
			then: {
				$0.uuid = .constant(uuidOfNewProfile)
				XCTAssertNoDifference(userDefaults.string(key: .activeProfileID), savedProfile.header.id.uuidString)
				$0.secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs = { idToDelete, _ in
					XCTAssertNoDifference(idToDelete, savedProfile.header.id)
				}
			}
		)

		// New active profile
		XCTAssertNoDifference(userDefaults.string(key: .activeProfileID), uuidOfNewProfile.uuidString)
	}

	func test__GIVEN__mismatch__WHEN__app_is_not_yet_unlocked__THEN__no_alert_is_displayed() async throws {
		let alertNotScheduled = expectation(
			description: "overlayWindowClient did NOT scheduled alert"
		)

		alertNotScheduled.isInverted = true // invert meaning we expect it to NOT be fulfilled.

		try await withTimeLimit(.slow) {
			try await withTestClients {
				// GIVEN saved profile
				$0.savedProfile(Profile.withOneAccount)
				// mistmatch deviceID
				$0.secureStorageClient.loadDeviceInfo = { .testValueBEEF }
				when(&$0)
			} operation: {
				let sut = ProfileStore.init()
				// UI needs some time, we still need the conditions to be correct
				// in order to get a failure here...
				try await Task.sleep(for: .milliseconds(50))
				// WHEN app is NOT yet unlocked
				// await sut.unlockedApp() // enabling this line SHOULD cause test to fail
			}

			func when(_ d: inout DependencyValues) {
				d.overlayWindowClient.scheduleAlertAwaitAction = { _ in
					// THEN NO alert is displayed
					alertNotScheduled.fulfill()
					return .dismissed // irrelevant, should not happen
				}
			}

			await self.nearFutureFulfillment(of: alertNotScheduled)
		}
	}

	func test__GIVEN__saved_profile__WHEN__deleteWallet__THEN__profile_gets_deleted_from_secureStorage() async throws {
		try await withTimeLimit {
			let deleteProfileAndMnemonicsByFactorSourceIDs_is_called = self.expectation(description: "deleteProfileAndMnemonicsByFactorSourceIDs_is_called")
			// GIVEN saved profile
			let saved = Profile.withOneAccount
			// WHEN deleteWallet
			try await self.doTestDeleteProfile(saved: saved) { d, p in
				// THEN profile gets deleted from secureStorage
				d.secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs = { id, _ in
					XCTAssertNoDifference(id, p.header.id)
					deleteProfileAndMnemonicsByFactorSourceIDs_is_called.fulfill()
				}
			}
			await self.nearFutureFulfillment(of: deleteProfileAndMnemonicsByFactorSourceIDs_is_called)
		}
	}

	func test__GIVEN__saved_profile__WHEN__deleteWallet__THEN__activeProfileID_is_deleted() async throws {
		let uuidOfNew = UUID()
		let userDefaults = UserDefaults.Dependency.ephemeral()
		try await withTimeLimit {
			// GIVEN saved profile
			let saved = Profile.withOneAccount
			// WHEN deleteWallet
			try await self.doTestDeleteProfile(saved: saved, userDefaults: userDefaults, given: {
				XCTAssertNoDifference(userDefaults.string(key: .activeProfileID), saved.header.id.uuidString)
			}) { d, _ in
				d.uuid = .constant(uuidOfNew)
			}
		}
		// THEN activeProfileID is deleted
		XCTAssertNoDifference(userDefaults.string(key: .activeProfileID), uuidOfNew.uuidString)
	}

	// FIXME: Maybe should probably be moved to SecureStorageClientTests..?
	func test__GIVEN__saved_profile__WHEN__deleteWallet_not_keepIcloud__THEN__profile_gets_removed_from_saved_headerlist() async throws {
		try await withTimeLimit(
			.slow,
			failOnTimeout: false // this times out in CI sometimes...
		) {
			// GIVEN saved profile
			let saved = Profile.withOneAccount
			// WHEN deleteWallet
			try await self.doTestDeleteProfile(
				saved: saved,
				keepInICloudIfPresent: false
			) { d, _ in
				d.secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs = SecureStorageClient.liveValue.deleteProfileAndMnemonicsByFactorSourceIDs

				d.keychainClient._getDataWithoutAuthForKey = { key in
					if key == saved.header.id.keychainKey {
						try! JSONEncoder.iso8601.encode(saved.snapshot())
					} else if key == profileHeaderListKeychainKey {
						try! JSONEncoder.iso8601.encode([saved.header])
					} else {
						fatalError("unknown key: \(key)")
					}
				}
				d.keychainClient._removeDataForKey = { key in
					// THEN profile gets removed from saved headerlist
					if key.rawValue.rawValue.hasPrefix("profileSnapshot - ") {
						XCTAssertEqual(key, saved.header.id.keychainKey)
					}
				}
			}
		}
	}

	func test__GIVEN__saved_profile__WHEN__deleteWallet_keepIcloud__THEN__iCloud_is_kept() async throws {
		try await withTimeLimit {
			// GIVEN saved profile
			let saved = Profile.withOneAccount
			try await self.doTestDeleteProfile(
				saved: saved,
				// WHEN deleteWallet keep iCloud
				keepInICloudIfPresent: true
			) { d, _ in
				// THEN iCloud is kept
				d.secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs = { _, isKeepingIcloud in
					XCTAssertTrue(isKeepingIcloud)
				}
			}
		}
	}

	func test__GIVEN__saved_profile__WHEN__deleteWallet_delete_in_iCloud__THEN__iCloud_is_not_kept() async throws {
		try await withTimeLimit {
			// GIVEN saved profile
			let saved = Profile.withOneAccount
			try await self.doTestDeleteProfile(
				saved: saved,
				// WHEN deleteWallet and delete in iCloud
				keepInICloudIfPresent: false
			) { d, _ in
				// THEN iCloud is not kept
				d.secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs = { _, isKeepingIcloud in
					XCTAssertFalse(isKeepingIcloud)
				}
			}
		}
	}

	func test__GIVEN__saved_profile_P__WHEN__deleteWallet__THEN__new_profile_Q_is_created() async throws {
		try await withTimeLimit {
			// GIVEN saved profile `P`
			let P = Profile.withOneAccountsDeviceInfo_ABBA_mnemonic_ZOO_VOTE
			// WHEN deleteWallet
			let Q: Profile = try await self.doTestDeleteProfile(
				saved: P
			) { d, _ in
				// THEN new profile Q is created
				d.mnemonicClient.generate = { _, _ in
					Mnemonic.testValueAbandonArt
				}
			}
			XCTAssertNotEqual(P, Q)
			XCTAssertNoDifference(Q.factorSources[0].id, PrivateHDFactorSource.testValueAbandonArt.factorSource.id.embed())
		}
	}

	func test__GIVEN__saved_profile__WHEN__deleteWallet__THEN__new_profile_is_saved_to_secureStorage() async throws {
		try await withTimeLimit {
			// GIVEN saved profile
			let newProfile = Profile.withNoAccountsDeviceInfo_ABBA_mnemonic_ABANDON_ART
			// WHEN deleteWallet
			try await self.doTestDeleteProfile(
				saved: Profile.withOneAccountsDeviceInfo_ABBA_mnemonic_ZOO_VOTE
			) { d, _ in
				d.mnemonicClient.generate = { _, _ in
					Mnemonic.testValueAbandonArt
				}
				d.uuid = .constant(newProfile.id)
				// THEN new profile is saved to secureStorage
				d.secureStorageClient.saveProfileSnapshot = {
					XCTAssertNoDifference($0, newProfile.snapshot())
				}
			}
		}
	}

	func test__GIVEN__saved_profile__WHEN__we_update_profile_without_ownership__THEN__ownership_conflict_alert_is_shown() async throws {
		try await withTimeLimit(.normal) {
			// GIVEN saved profile
			let saved = Profile.withOneAccountsDeviceInfo_ABBA_mnemonic_ABANDON_ART
			let profileHasBeenUpdated = LockIsolated<Bool>(false)
			let ownership_conflict_alert_is_shown = self.expectation(description: "ownership conflict alert is shown")

			try await withTestClients {
				$0.savedProfile(saved)
				when(&$0)
				then(&$0)
			} operation: {
				let sut = ProfileStore()
				await sut.unlockedApp()
				// WHEN we update profile...
				do {
					try await sut.updating {
						$0.header.lastModified = Date()
						profileHasBeenUpdated.setValue(true)
					}
					return XCTFail("Expected to throw")
				} catch {
					// expected to throw
				}
			}

			func when(_ d: inout DependencyValues) {
				d.secureStorageClient.loadProfileSnapshot = { _ in
					profileHasBeenUpdated.withValue { hasBeenUpdated in
						if hasBeenUpdated {
							var modified = saved
							modified.header.lastUsedOnDevice = .testValueBEEF // 0xBEEF != 0xABBA
							// WHEN ... without ownership
							return modified.snapshot()
						} else {
							return saved.snapshot()
						}
					}
				}
			}

			func then(_ d: inout DependencyValues) {
				d.overlayWindowClient.scheduleAlertAwaitAction = { alert in
					XCTAssertNoDifference(
						alert.message, TextState(overlayClientProfileStoreOwnershipConflictTextState)
					)
					// THEN ownership conflict alert is shown
					ownership_conflict_alert_is_shown.fulfill()
					return .dismissed
				}
			}

			await self.nearFutureFulfillment(of: ownership_conflict_alert_is_shown)
		}
	}
}

// MARK: - ProfileStoreAsyncSequenceTests
final class ProfileStoreAsyncSequenceTests: TestCase {
	func test__GIVEN__no_profile__WHEN_add_first_network__THEN__RadixGateway_is_emitted() async throws {
		try await withTimeLimit {
			try await self.doTestAsyncSequence(
				// GIVEN no profile
				savedProfile: nil,
				arrange: { sut in
					await sut.currentGatewayValues()
				},
				act: { sut in
					try await sut.updating {
						// WHEN add first network (first account adds first network)
						try $0.addAccount(
							.testValue
						)
					}
				},
				// THEN Radix.Gatewat is emitted
				assert: [Radix.Gateway.mainnet]
			)
		}
	}

	func test__GIVEN__no_profile__WHEN_add_first_account__THEN__account_is_emitted() async throws {
		try await withTimeLimit {
			let firstAccount: Profile.Network.Account = .testValueIdx0
			try await self.doTestAsyncSequence(
				// GIVEN no profile
				savedProfile: nil,
				arrange: { sut in
					await sut.accountValues()
				},
				act: { sut in
					try await sut.updating {
						// WHEN add first account
						try $0.addAccount(
							firstAccount
						)
					}
				},
				assert: [
					// THEN account is emitted
					[firstAccount],
				]
			)
		}
	}

	func test__GIVEN__profile_with_one_account__WHEN_add_2nd_account__THEN__both_accounts_are_emitted() async throws {
		try await withTimeLimit(.slow) {
			var profile = Profile.withNoAccounts
			let firstAccount: Profile.Network.Account = .testValueIdx0
			// GIVEN: Profile with one account
			try profile.addAccount(firstAccount)

			let secondAccount: Profile.Network.Account = .testValueIdx1
			try await self.doTestAsyncSequence(
				savedProfile: profile,
				arrange: { sut in
					await sut.accountValues()
				},
				act: { sut in
					try await sut.updating {
						// WHEN add 2nd account
						try $0.addAccount(
							secondAccount
						)
					}
				},
				assert: [
					[firstAccount],
					// THEN both accounts are emitted
					[firstAccount, secondAccount],
				]
			)
		}
	}
}

extension ProfileStoreAsyncSequenceTests {
	private func doTestAsyncSequence<T: Sendable & Hashable>(
		savedProfile: Profile?,
		arrange: @escaping @Sendable (ProfileStore) async -> AnyAsyncSequence<T>,
		act: (ProfileStore) async throws -> Void,
		assert expected: Set<T>
	) async throws {
		try await withTestClients {
			if let savedProfile {
				$0.savedProfile(savedProfile)
			} else {
				$0.noProfile()
			}
		} operation: {
			let sut = ProfileStore()
			let listenerSetup = self.expectation(description: "listener setup")
			let task = Task {
				let asyncSequence = await arrange(sut)
				var values = Set<T>()
				listenerSetup.fulfill()
				for try await value in asyncSequence {
					print("🔮 value: \(value)")
					values.insert(value)
					if values.count >= expected.count {
						return values
					}
				}
				return values
			}
			await self.nearFutureFulfillment(of: listenerSetup)
			try await act(sut)
			let actual = try await task.value
			XCTAssertEqual(actual, expected)
		}
	}
}

extension ProfileStoreExistingProfileTests {
	private func doTestMismatch(
		savedProfile: Profile,
		userDefaults: UserDefaults.Dependency = .ephemeral(),
		action: OverlayWindowClient.Item.AlertAction,
		then: @escaping @Sendable (inout DependencyValues) -> Void = { _ in },
		result assertResult: @escaping @Sendable (Profile) -> Void = { _ in }
	) async throws {
		let alertScheduled = expectation(
			description: "overlayWindowClient has scheduled alert"
		)
		try await withTimeLimit(.slow) {
			let result = await withTestClients(userDefaults: userDefaults) {
				// GIVEN saved profile
				$0.savedProfile(savedProfile, userDefaults: userDefaults)
				// mistmatch deviceID
				$0.secureStorageClient.loadDeviceInfo = { .testValueBEEF }
				when(&$0)
				then(&$0)
			} operation: { [self] in
				let sut = ProfileStore.init()
				await sut.unlockedApp() // must unlock to allow alert to be displayed
				// The scheduling of the alert needs some time...
				await nearFutureFulfillment(of: alertScheduled)
				return await sut.profile
			}

			func when(_ d: inout DependencyValues) {
				d.overlayWindowClient.scheduleAlertAwaitAction = { alert in
					XCTAssertNoDifference(
						alert.message, overlayClientProfileStoreOwnershipConflictTextState
					)
					alertScheduled.fulfill()
					return action
				}
			}

			assertResult(result)
		}
	}

	@discardableResult
	private func doTestDeleteProfile(
		saved: Profile,
		userDefaults: UserDefaults.Dependency = .ephemeral(),
		keepInICloudIfPresent: Bool = true,
		given: () -> Void = {},
		_ then: (inout DependencyValues, _ deletedProfile: Profile) -> Void
	) async throws -> Profile {
		try await withTestClients(userDefaults: userDefaults) {
			$0.savedProfile(saved, userDefaults: userDefaults) // GIVEN saved profile
			given()
			$0.secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs = { _, _ in }
			then(&$0, saved) // THEN ...
		} operation: {
			let sut = ProfileStore()
			// WHEN deleteProfile
			try await sut.deleteProfile(keepInICloudIfPresent: keepInICloudIfPresent)
			return await sut.profile
		}
	}
}
