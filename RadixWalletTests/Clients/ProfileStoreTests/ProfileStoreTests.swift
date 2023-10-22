import DependenciesAdditions
@testable import Radix_Wallet_Dev
import XCTest

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
	}

	mutating func savedProfile(_ savedProfile: Profile) {
		_profile(savedProfile)
	}

	mutating func noProfile() {
		_profile(nil)
	}
}

// MARK: - ProfileStoreTests
final class ProfileStoreTests: TestCase {
	func test__GIVEN__saved_profile__WHEN__init__THEN__saved_profile_is_used() async throws {
		try await withTimeLimit {
			// GIVEN saved profile
			let saved = Profile.withOneAccount

			let used = await withTestClients {
				$0.savedProfile(saved)
			} operation: {
				// WHEN ProfileStore.init()
				await ProfileStore().profile
			}

			// THEN saved profile is used.
			XCTAssertNoDifference(saved, used)
		}
	}

	func test__GIVEN__no_profile__WHEN__init__THEN__new_profile_without_network_is_used() async throws {
		try await withTimeLimit(.normal) {
			let newProfile = await withTestClients {
				$0.noProfile()
			} operation: {
				await ProfileStore().profile
			}

			XCTAssertNoDifference(newProfile.networks.count, 0)
		}
	}

	func test__WHEN__init__THEN__24_english_word_ephmeral_mnemonic_is_generated() async {
		let profileID: UUID = 0
		let deviceID: UUID = 1

		withDependencies {
			$0.device.$name = deviceName
			$0.device.$model = deviceModel.rawValue
			$0.uuid = .incrementing
			$0.mnemonicClient.generate = {
				XCTAssertNoDifference($0, BIP39.WordCount.twentyFour)
				XCTAssertNoDifference($1, BIP39.Language.english)
				return .testValue
			}
			$0.secureStorageClient.loadProfileHeaderList = { nil }
			$0.secureStorageClient.saveProfileHeaderList = {
				XCTAssertNoDifference($0.count, 1)
			}
			$0.userDefaultsClient.setString = { v, _ in
				if v == UserDefaultsClient.Key.activeProfileID.rawValue {
					XCTAssertNoDifference(v, profileID.uuidString)
				}
			}
			$0.secureStorageClient.saveMnemonicForFactorSource = { XCTAssertNoDifference($0.factorSource.kind, .device) }
			$0.secureStorageClient.saveProfileSnapshot = { snapsot in
				XCTAssertNoDifference(snapsot.header.id, profileID)
				XCTAssertNoDifference(snapsot.header.lastUsedOnDevice.id, deviceID)
				XCTAssertNoDifference(snapsot.header.creatingDevice.id, deviceID)
			}
			$0.secureStorageClient.loadProfile = { _ in nil }
			$0.secureStorageClient.loadDeviceInfo = {
				DeviceInfo(
					description: "iPhone (iPhone)",
					id: deviceID,
					date: Date(timeIntervalSince1970: 0)
				)
			}
			$0.date = .constant(Date(timeIntervalSince1970: 0))
			$0.userDefaultsClient.stringForKey = { _ in
				nil
			}
		} operation: {
			ProfileStore()
		}
	}

	func test_fullOnboarding_assert_mnemonic_persisted_when_commitEphemeral_called() async throws {
		let privateFactor = withDependencies {
			$0.date = .constant(Date(timeIntervalSince1970: 0))
		} operation: {
			PrivateHDFactorSource.testValue
		}

		try await doTestFullOnboarding(
			privateFactor: privateFactor,
			assertMnemonicWithPassphraseSaved: {
				XCTAssertNoDifference($0, privateFactor.mnemonicWithPassphrase)
			}
		)
	}

	func test_fullOnboarding_assert_factorSource_persisted_when_commitEphemeral_called() async throws {
		try await doTestFullOnboarding(
			privateFactor: .testValue,
			assertFactorSourceSaved: { factorSource in
				XCTAssertNoDifference(factorSource.kind, .device)
				XCTAssertFalse(factorSource.supportsOlympia)
				XCTAssertNoDifference(factorSource.hint.name, deviceName)
				XCTAssertNoDifference(factorSource.hint.model, deviceModel)
			}
		)
	}

	func test_fullOnboarding_assert_profileSnapshot_persisted_when_commitEphemeral_called() async throws {
		let profileID = UUID()
		let privateFactor = withDependencies {
			$0.date = .constant(Date(timeIntervalSince1970: 0))
		} operation: {
			PrivateHDFactorSource.testValue
		}

		try await doTestFullOnboarding(
			profileID: profileID,
			privateFactor: privateFactor,
			assertProfileSaved: { profileSnapshot in

				XCTAssertNoDifference(profileSnapshot.id, profileID)

				XCTAssertNoDifference(
					profileSnapshot.factorSources.first,
					privateFactor.factorSource.embed()
				)
				XCTAssertNoDifference(
					profileSnapshot.header.creatingDevice.description,
					expectedDeviceDescription
				)
			}
		)
	}
}

private extension ProfileStoreTests {
	func doTestFullOnboarding(
		profileID: UUID = .init(),
		privateFactor: PrivateHDFactorSource,
		provideProfileSnapshotLoaded: Data? = nil,
		assertMnemonicWithPassphraseSaved: (@Sendable (MnemonicWithPassphrase) -> Void)? = { _ in /* noop */ },
		assertFactorSourceSaved: (@Sendable (DeviceFactorSource) -> Void)? = { _ in /* noop */ },
		assertProfileSaved: (@Sendable (Profile) -> Void)? = { _ in /* noop */ }
	) async throws {
		let profileSaved = ActorIsolated<Profile?>(nil)
		let exp = expectation(description: "saveProfile")
		try await withDependencies {
			$0.uuid = .constant(profileID)
			$0.mnemonicClient.generate = { _, _ in privateFactor.mnemonicWithPassphrase.mnemonic }
			$0.device.$name = deviceName
			$0.device.$model = deviceModel.rawValue
			$0.secureStorageClient.loadProfile = { _ in
				nil
			}
			$0.secureStorageClient.loadProfileHeaderList = {
				nil
			}
			$0.secureStorageClient.saveMnemonicForFactorSource = { privateFactorSource in
				if assertMnemonicWithPassphraseSaved == nil, assertFactorSourceSaved == nil {
					XCTFail("Did not expect `saveMnemonicForFactorSource` to be called")
				} else {
					if let assertMnemonicWithPassphraseSaved {
						assertMnemonicWithPassphraseSaved(privateFactorSource.mnemonicWithPassphrase)
					}
					if let assertFactorSourceSaved {
						assertFactorSourceSaved(privateFactorSource.factorSource)
					}
				}
			}
			$0.secureStorageClient.saveProfileSnapshot = { new in
				Task {
					await profileSaved.setValue(Profile(snapshot: new))
					exp.fulfill()
				}
			}
			$0.date = .constant(Date(timeIntervalSince1970: 0))
			$0.userDefaultsClient.stringForKey = { _ in
				"BABE1442-3C98-41FF-AFB0-D0F5829B020D"
			}
			$0.secureStorageClient.loadDeviceInfo = {
				DeviceInfo(
					description: "iPhone (iPhone)",
					id: .init(uuidString: "BABE1442-3C98-41FF-AFB0-D0F5829B020D")!,
					date: Date(timeIntervalSince1970: 0)
				)
			}
			$0.userDefaultsClient.setString = { _, _ in }
			$0.secureStorageClient.loadProfileHeaderList = {
				nil
			}
			$0.secureStorageClient.saveProfileHeaderList = { _ in }
		} operation: {
			let sut = ProfileStore()
			var profile: Profile?
			for try await profileValue in await sut.values() {
				profile = profileValue
				break
			}
			await fulfillment(of: [exp], timeout: 1)
			let maybeSavedProfile = await profileSaved.value
			if let assertProfileSaved {
				let profileSaved = try XCTUnwrap(maybeSavedProfile)
				XCTAssertNoDifference(
					profileSaved,
					profile
				)
				assertProfileSaved(profileSaved)
			} else {
				XCTFail("Did not expect `saveProfile` to be called")
			}
		}
	}
}

private let deviceName: String = "iPhone"
private let deviceModel: DeviceFactorSource.Hint.Model = "iPhone"
private let expectedDeviceDescription = DeviceInfo.deviceDescription(
	name: deviceName,
	model: deviceModel.rawValue
)

extension PrivateHDFactorSource {
	static let testValue: Self = withDependencies {
		$0.date = .constant(Date(timeIntervalSince1970: 0))
	} operation: {
		Self.testValue(name: deviceName, model: deviceModel)
	}
}

extension ProfileStore {
	func update(profile: Profile) throws {
		try _update(profile: profile)
	}
}
