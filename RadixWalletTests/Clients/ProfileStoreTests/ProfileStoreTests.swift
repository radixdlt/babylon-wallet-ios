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
		try await withTimeLimit {
			let newProfile = await withTestClients {
				// GIVEN no profile
				$0.noProfile()
			} operation: {
				// WHEN ProfileStore.init()
				await ProfileStore().profile
			}

			// THEN new profile without network is used
			XCTAssertNoDifference(newProfile.networks.count, 0)
		}
	}

	func test__GIVEN__no_profile__WHEN__init__THEN__24_word_mnemonic_is_generated() async throws {
		try await withTimeLimit {
			let wordCountUsed = LockIsolated<BIP39.WordCount?>(nil)
			try await withTestClients {
				// GIVEN no profile
				$0.noProfile()

				$0.mnemonicClient.generate = { wordCount, _ in
					wordCountUsed.setValue(wordCount)
					return try Mnemonic(wordCount: wordCount, language: .english)
				}
			} operation: {
				// WHEN ProfileStore.init()
				await ProfileStore()
			}

			wordCountUsed.withValue {
				// THEN 24 word mnemonic is generated
				XCTAssertNoDifference($0, .twentyFour)
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
				await ProfileStore().profile
			}

			XCTAssertNoDifference(
				profile.factorSources.first.id.description,
				// THEN profile uses newly generated DeviceFactorSource
				"device:09a501e4fafc7389202a82a3237a405ed191cdb8a4010124ff8e2c9259af1327"
			)
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
