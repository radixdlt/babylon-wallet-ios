import ClientTestingPrelude
import Cryptography
import LocalAuthenticationClient
@testable import Profile
@testable import ProfileStore
import SecureStorageClient

// MARK: - ProfileStoreTests
final class ProfileStoreTests: TestCase {
	func test__WHEN__init__THEN__24_english_word_ephmeral_mnemonic_is_generated() async {
		await withDependencies {
			#if canImport(UIKit)
			$0.device.$name = deviceName.rawValue
			$0.device.$model = deviceModel.rawValue
			#endif
			$0.uuid = .incrementing
			$0.mnemonicClient.generate = {
				XCTAssertNoDifference($0, BIP39.WordCount.twentyFour)
				XCTAssertNoDifference($1, BIP39.Language.english)
				return .testValue
			}
			$0.secureStorageClient.saveMnemonicForFactorSource = { XCTAssertNoDifference($0.factorSource.kind, .device) }
			$0.secureStorageClient.loadProfileSnapshotData = { _ in nil }
			$0.secureStorageClient.loadDeviceIdentifier = {
				.init(uuidString: "BABE1442-3C98-41FF-AFB0-D0F5829B020D")!
			}
			$0.date = .constant(Date(timeIntervalSince1970: 0))
			$0.userDefaultsClient.stringForKey = { _ in
				"BABE1442-3C98-41FF-AFB0-D0F5829B020D"
			}
		} operation: {
			_ = await ProfileStore()
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
			assertProfileSnapshotSaved: { profileSnapshot in

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
		assertProfileSnapshotSaved: (@Sendable (ProfileSnapshot) -> Void)? = { _ in /* noop */ }
	) async throws {
		let profileSnapshotSavedIntoSecureStorage = ActorIsolated<ProfileSnapshot?>(nil)
		try await withDependencies {
			$0.uuid = .constant(profileID)
			$0.mnemonicClient.generate = { _, _ in privateFactor.mnemonicWithPassphrase.mnemonic }
			#if canImport(UIKit)
			$0.device.$name = deviceName.rawValue
			$0.device.$model = deviceModel.rawValue
			#endif
			$0.secureStorageClient.loadProfileSnapshotData = { _ in
				provideProfileSnapshotLoaded
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
			$0.secureStorageClient.saveProfileSnapshot = {
				await profileSnapshotSavedIntoSecureStorage.setValue($0)
			}
			$0.date = .constant(Date(timeIntervalSince1970: 0))
			$0.userDefaultsClient.stringForKey = { _ in
				"BABE1442-3C98-41FF-AFB0-D0F5829B020D"
			}
			$0.secureStorageClient.loadDeviceIdentifier = {
				.init(uuidString: "BABE1442-3C98-41FF-AFB0-D0F5829B020D")!
			}
			$0.userDefaultsClient.setString = { _, _ in }
			$0.secureStorageClient.loadProfileHeaderList = {
				nil
			}
			$0.secureStorageClient.saveProfileHeaderList = { _ in }
		} operation: {
			let sut = await ProfileStore()
			var profile: Profile?
			for await state in await sut.profileStateSubject {
				switch state {
				case let .ephemeral(ephemeral):
					profile = ephemeral.profile
					XCTAssertNoDifference(
						ephemeral.profile.factorSources.first,
						privateFactor.factorSource.embed()
					)
					try await sut.commitEphemeral()
				case let .persisted(persistedProfile):
					XCTAssertNoDifference(
						persistedProfile,
						profile
					)
					return
				}
			}

			let profileSnapshotMaybe = await profileSnapshotSavedIntoSecureStorage.value

			if let assertProfileSnapshotSaved {
				let profileSnapshot = try XCTUnwrap(profileSnapshotMaybe)
				XCTAssertNoDifference(
					profileSnapshot,
					profile?.snapshot()
				)
				assertProfileSnapshotSaved(profileSnapshot)
			} else {
				XCTFail("Did not expect `saveProfileSnapshot` to be called")
			}
		}
	}
}

#if canImport(UIKit)
private let deviceName: DeviceFactorSource.Hint.Name = "NAME"
private let deviceModel: DeviceFactorSource.Hint.Model = "MODEL"
private let expectedDeviceDescription = ProfileStore.deviceDescription(
	name: deviceName,
	model: deviceModel
)
#else
private let expectedDeviceDescription = ProfileStore.macOSDeviceDescriptionFallback
#endif

extension PrivateHDFactorSource {
	static let testValue: Self = withDependencies {
		$0.date = .constant(Date(timeIntervalSince1970: 0))
	} operation: {
		Self.testValue(name: deviceName, model: deviceModel)
	}
}
