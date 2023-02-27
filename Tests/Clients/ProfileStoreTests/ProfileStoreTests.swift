import ClientTestingPrelude
import Cryptography
import LocalAuthenticationClient
import Profile
@testable import ProfileModels
@testable import ProfileStore
import SecureStorageClient

// MARK: - ProfileStoreTests
final class ProfileStoreTests: TestCase {
	func test__WHEN__init__THEN__24_english_word_ephmeral_mnemonic_is_generated() {
		withDependencies {
			$0.uuid = .incrementing
			$0.mnemonicClient.generate = {
				XCTAssertNoDifference($0, BIP39.WordCount.twentyFour)
				XCTAssertNoDifference($1, BIP39.Language.english)
				return .testValue
			}
			$0.secureStorageClient.loadProfileSnapshotData = { nil }
		} operation: {
			_ = ProfileStore()
		}
	}

	func test_fullOnboarding_assert_mnemonic_persisted_when_commitEphemeral_called() async throws {
		let privateFactor = PrivateHDFactorSource.testValue

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
				XCTAssertNoDifference(factorSource.hint, expectedDeviceDescription)
			}
		)
	}

	func test_fullOnboarding_assert_profileSnapshot_persisted_when_commitEphemeral_called() async throws {
		let profileID = UUID()
		let privateFactor = PrivateHDFactorSource.testValue

		try await doTestFullOnboarding(
			profileID: profileID,
			privateFactor: privateFactor,
			assertProfileSnapshotSaved: { profileSnapshot in
				XCTAssertNoDifference(profileSnapshot.id, profileID)

				XCTAssertNoDifference(
					profileSnapshot.factorSources.first.ignoringDate(),
					privateFactor.factorSource.with(deviceDescription: expectedDeviceDescription).ignoringDate()
				)
				XCTAssertNoDifference(profileSnapshot.creatingDevice, expectedDeviceDescription)
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
		assertFactorSourceSaved: (@Sendable (FactorSource) -> Void)? = { _ in /* noop */ },
		assertProfileSnapshotSaved: (@Sendable (ProfileSnapshot) -> Void)? = { _ in /* noop */ }
	) async throws {
		let profileSnapshotSavedIntoSecureStorage = ActorIsolated<ProfileSnapshot?>(nil)
		try await withDependencies {
			$0.uuid = .constant(profileID)
			$0.mnemonicClient.generate = { _, _ in privateFactor.mnemonicWithPassphrase.mnemonic }
			#if canImport(UIKit)
			$0.device.$model = "MODEL"
			$0.device.$name = "NAME"
			#endif
			$0.secureStorageClient.loadProfileSnapshotData = {
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
		} operation: {
			let stateAsyncSubject: AsyncCurrentValueSubject<ProfileStore.State> = .init(ProfileStore.newEphemeral())

			Task {
				var profile: Profile?
				// N.B. normally async tests like this requires use of `Set` since ordering
				// is not guaranteed by `Task`, however, the `ProfileStore` is a state machine
				// only allowing for certain state transitions
				var values: [ProfileStore.State.Discriminator] = .init()
				let expectedValues: [ProfileStore.State.Discriminator] = [.newWithEphemeral, .ephemeral, .persisted]
				for await state in stateAsyncSubject.prefix(expectedValues.count) {
					values.append(state.discriminator)
					switch state {
					case let .newWithEphemeral(newEphemeral):
						profile = newEphemeral.profile
						XCTAssertNoDifference(newEphemeral.privateFactorSource.mnemonicWithPassphrase, privateFactor.mnemonicWithPassphrase)
					case let .ephemeral(ephemeral):
						XCTAssertNoDifference(ephemeral.profile, profile)
						XCTAssertNoDifference(ephemeral.privateFactorSource.mnemonicWithPassphrase, privateFactor.mnemonicWithPassphrase)
					case let .persisted(persistedProfile):

						XCTAssertNoDifference(
							persistedProfile,
							profile?.with(creatingDevice: expectedDeviceDescription)
						)
					}
				}
				XCTAssertNoDifference(values, expectedValues)
			}

			let sut = ProfileStore(state: stateAsyncSubject)
			try await sut.commitEphemeral()
			let profileSnapshotMaybe = await profileSnapshotSavedIntoSecureStorage.value
			if let assertProfileSnapshotSaved {
				let profileSnapshot = try XCTUnwrap(profileSnapshotMaybe)
				assertProfileSnapshotSaved(profileSnapshot)
			} else {
				XCTFail("Did not expect `saveProfileSnapshot` to be called")
			}
		}
	}
}

private var expectedDeviceDescription: NonEmptyString {
	#if canImport(UIKit)
	return "NAME (MODEL)"
	#else
	return "macOS"
	#endif
}

extension PrivateHDFactorSource {
	static let testValue: Self = {
		let mnemonicWithPassphrase = MnemonicWithPassphrase.testValue
		let factorSource = try! FactorSource.babylon(mnemonicWithPassphrase: mnemonicWithPassphrase, hint: "ProfileStoreUnitTest")
		return try! .init(mnemonicWithPassphrase: mnemonicWithPassphrase, factorSource: factorSource)
	}()
}

extension MnemonicWithPassphrase {
	static let testValue: Self = .init(mnemonic: .testValue)
}

extension Mnemonic {
	static let testValue: Self = try! Mnemonic(
		phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
		language: .english
	)
}

extension FactorSource {
	func with(deviceDescription: NonEmptyString) -> Self {
		var copy = self
		copy.hint = deviceDescription
		return copy
	}
}

extension Profile {
	func with(creatingDevice: NonEmptyString) -> Self {
		var copy = self
		copy.update(deviceDescription: creatingDevice)
		return copy
	}

	func ignoringCreatingDevice() -> Self {
		with(creatingDevice: "ignored")
	}
}
