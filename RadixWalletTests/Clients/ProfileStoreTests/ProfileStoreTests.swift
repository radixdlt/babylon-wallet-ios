@testable import Radix_Wallet_Dev
import XCTest

// MARK: - ProfileStoreTests
final class ProfileStoreTests: TestCase {
	/// This test method has not been implemented with any particular thoughts in mind
	/// mostly creating a bunch of unstructured task and reading/setting profile on shared
	/// profile store interleaved with some `Task.yield()`'s which resulted in failures before
	/// ProfileStore was migrated to use ManagedAtomicLazyReference, for more reading about this
	/// see: https://forums.swift.org/t/is-this-an-ok-solution-to-achieve-shared-instance-of-actor-using-async-init/63528/2
	func test_assert_ProfileStore_is_reentrance_free() async throws {
		try await withDependencies {
			#if canImport(UIKit)
			$0.device.$name = deviceName
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
			$0.secureStorageClient.getDeviceIdentifierSetIfNil = {
				$0
			}
			$0.date = .constant(Date(timeIntervalSince1970: 0))
			$0.userDefaultsClient.stringForKey = { _ in
				"BABE1442-3C98-41FF-AFB0-D0F5829B020D"
			}
		} operation: {
			let t0 = Task {
				await ProfileStore.shared
			}
			await Task.yield()
			var profile = await ProfileStore.shared.profile
			await Task.yield()
			let t1 = Task {
				await ProfileStore.shared
			}
			let t2 = Task {
				await ProfileStore.shared
			}
			await Task.yield()
			profile = await ProfileStore.shared.profile
			await Task.yield()
			let t3 = Task {
				await ProfileStore.shared
			}
			await Task.yield()
			try await ProfileStore.shared.update(profile: profile)
			await Task.yield()
			let t4 = Task {
				await ProfileStore.shared
			}
			let t5 = Task {
				await ProfileStore.shared
			}
			await Task.yield()
			profile = await ProfileStore.shared.profile
			await Task.yield()
			let t6 = Task {
				await ProfileStore.shared
			}
			let t7 = Task {
				await ProfileStore.shared
			}
			await Task.yield()
			try await ProfileStore.shared.update(profile: profile)
			await Task.yield()
			let t8 = Task {
				await ProfileStore.shared
			}
			let t9 = Task {
				await ProfileStore.shared
			}

			let tasks = [t0, t1, t2, t3, t4, t5, t6, t7, t8, t9]
			var values = Set<Profile.ID>()
			for task in tasks {
				let profile = await task.value.profile
				values.insert(profile.id)
			}
			XCTAssertEqual(values.count, 1) // will fail for `test_reentrant` sometimes
		}
	}

	func test__WHEN__init__THEN__24_english_word_ephmeral_mnemonic_is_generated() async {
		await withDependencies {
			#if canImport(UIKit)
			$0.device.$name = deviceName
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
			$0.device.$name = deviceName
			$0.device.$model = deviceModel.rawValue
			#endif
			$0.secureStorageClient.loadProfileSnapshotData = { _ in
				provideProfileSnapshotLoaded
			}
			$0.secureStorageClient.getDeviceIdentifierSetIfNil = {
				$0
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
			for await state in await sut.profileSubject {
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
private let deviceName: String = "NAME"
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
