import ClientTestingPrelude
import Cryptography
import LocalAuthenticationClient
import Profile
@_spi(Test) import SecureStorageClient

// MARK: - ProfileStoreTests
final class ProfileStoreTests: TestCase {
	func test__WHEN__init__THEN__24_english_word_ephmeral_mnemonic_is_generated() {
		withDependencies {
			$0.uuid = .incrementing
			$0.mnemonicClient.generate = {
				XCTAssertEqual($0, BIP39.WordCount.twentyFour)
				XCTAssertEqual($1, BIP39.Language.english)
				return .zoo
			}
		} operation: {
			_ = ProfileStore.shared
		}
	}

	func test__GIVEN__init_ProfileStore_found_no_snapshot_saved__WHEN__user_commitsEphemeral__THEN__snapshot_and_mnemonic_is_saved() async throws {
		let profileID = UUID()
		let profileSnapshotSavedIntoSecureStorage = ActorIsolated<ProfileSnapshot?>(nil)
		try await withDependencies {
			$0.uuid = .constant(profileID)
			$0.mnemonicClient.generate = { _, _ in .zoo }
			#if canImport(UIKit)
			$0.device.$model = "MODEL"
			$0.device.$name = "NAME"
			#endif
			$0.secureStorageClient.loadProfileSnapshotData = { nil }
			$0.secureStorageClient.saveMnemonicForFactorSource = {
				XCTAssertEqual($0.mnemonicWithPassphrase.mnemonic, .zoo)
				XCTAssertEqual($0.factorSource.hint, "NAME (MODEL)")
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
					case let .newWithEphemeral(newEphemeralProfile, privateHDFactorSource):
						profile = newEphemeralProfile
						XCTAssertEqual(privateHDFactorSource.mnemonicWithPassphrase.mnemonic, Mnemonic.zoo)
					case let .ephemeral(ephemeralProfile, privateHDFactorSource):
						XCTAssertEqual(ephemeralProfile, profile)
						XCTAssertEqual(privateHDFactorSource.mnemonicWithPassphrase.mnemonic, Mnemonic.zoo)
					case let .persisted(persistedProfile):
						XCTAssertEqual(persistedProfile, profile)
					}
				}
				XCTAssertEqual(values, [.newWithEphemeral, .ephemeral, .persisted])
			}
			try await ProfileStore.shared.commitEphemeral()
			let profileSnapshot = await profileSnapshotSavedIntoSecureStorage.value
			XCTAssertEqual(profileSnapshot?.id, profileID)
			#if canImport(UIKit)
			XCTAssertEqual(profileSnapshot?.creatingDevice, "NAME (MODEL)")
			#endif
		}
	}
}

extension Mnemonic {
	static let zoo: Self = try! Mnemonic(
		phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
		language: .english
	)
}

extension ProfileStore.State {
	enum Disciminator: String, Sendable, Hashable {
		case newWithEphemeral, ephemeral, persisted
	}

	var discriminator: Disciminator {
		switch self {
		case .newWithEphemeral: return .newWithEphemeral
		case .ephemeral: return .ephemeral
		case .persisted: return .persisted
		}
	}
}
