import ClientTestingPrelude
import Cryptography
import LocalAuthenticationClient
import Profile
import SecureStorageClient
@_spi(Test) import ProfileStore

// MARK: - ProfileStoreTests
final class ProfileStoreTests: TestCase {
	func test__WHEN__init__THEN__24_english_word_ephmeral_mnemonic_is_generated() {
		withDependencies {
			$0.uuid = .incrementing
			$0.mnemonicClient.generate = {
				XCTAssertEqual($0, BIP39.WordCount.twentyFour)
				XCTAssertEqual($1, BIP39.Language.english)
				return .testValue
			}
			$0.secureStorageClient.loadProfileSnapshotData = { nil }
		} operation: {
			_ = ProfileStore.shared
		}
	}

	func test_fullOnboarding_assert_mnemonic_persisted_when_commitEphemeral_called() async throws {
		let privateFactor = PrivateHDFactorSource.testValue

		try await doTestFullOnboarding(
			privateFactor: privateFactor,
			assertMnemonicWithPassphraseSaved: {
				XCTAssertEqual($0, privateFactor.mnemonicWithPassphrase)
			}
		)
	}

	func test_fullOnboarding_assert_factorSource_persisted_when_commitEphemeral_called() async throws {
		try await doTestFullOnboarding(
			privateFactor: .testValue,
			assertFactorSourceSaved: { factorSource in
				XCTAssertEqual(factorSource.kind, .device)
				XCTAssertFalse(factorSource.supportsOlympia)
				#if canImport(UIKit)
				XCTAssertEqual(factorSource.hint, "NAME (MODEL)")
				#else
				XCTAssertEqual(factorSource.hint, "macOS")
				#endif
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
				let expectedDeviceDescription: NonEmptyString = "NAME (MODEL)"
				XCTAssertEqual(profileSnapshot.id, profileID)
				XCTAssertNoDifference(profileSnapshot.factorSources.first, privateFactor.factorSource.with(deviceDescription: expectedDeviceDescription))

				#if canImport(UIKit)
				XCTAssertEqual(profileSnapshot.creatingDevice, expectedDeviceDescription)
				#endif
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
			Task {
				var profile: Profile?
				// N.B. normally async tests like this requires use of `Set` since ordering
				// is not guaranteed by `Task`, however, the `ProfileStore` is a state machine
				// only allowing for certain state transitions
				var values = [ProfileStore.State.Disciminator]()
				for await state in await ProfileStore.shared.state {
					values.append(state.discriminator)
					switch state {
					case let .newWithEphemeral(newEphemeral):
						profile = newEphemeral.profile
						XCTAssertEqual(newEphemeral.privateFactorSource.mnemonicWithPassphrase, privateFactor.mnemonicWithPassphrase)
					case let .ephemeral(ephemeral):
						XCTAssertEqual(ephemeral.profile, profile)
						XCTAssertEqual(ephemeral.privateFactorSource.mnemonicWithPassphrase, privateFactor.mnemonicWithPassphrase)
					case let .persisted(persistedProfile):
						XCTAssertEqual(persistedProfile, profile)
					}
				}
				XCTAssertEqual(values, [.newWithEphemeral, .ephemeral, .persisted])
			}
			try await ProfileStore.shared.commitEphemeral()
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

extension Optional {
	static var expectToNotBeCalled: Self { .none }
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
