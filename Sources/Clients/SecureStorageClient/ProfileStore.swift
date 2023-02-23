import ClientPrelude
import Cryptography
import Profile

#if DEBUG
// Only used by tests.
extension DispatchSemaphore: @unchecked Sendable {}
#endif

// MARK: - ProfileStore
public final actor ProfileStore: GlobalActor {
	@Dependency(\.assert) var assert
	@Dependency(\.secureStorageClient) var secureStorageClient

	public static let shared = ProfileStore()

	private var state: State

	private init() {
		self.state = Self.newEphemeral()
		#if DEBUG
		// For unit tests we'd like to wait for init Task to complete.
		let semaphore = DispatchSemaphore(value: 0)
		// Must do this in a separate thread, otherwise we block the concurrent thread pool
		DispatchQueue.global(qos: .userInitiated).async {
			Task {
				await self.restoreFromSecureStorageIfAble()
				semaphore.signal()
			}
		}
		semaphore.wait()
		#else
		Task {
			await restoreFromSecureStorageIfAble()
		}
		#endif
	}
}

// MARK: ProfileStore.State
extension ProfileStore {
	/// The different possible states of Profile store.
	fileprivate enum State: Sendable {
		/// The initial state, set during start of init, have not yet
		/// checked Secure Storage for an potentially existing stored
		/// profile, which require an async Task to be done at end of
		/// init (which will complete after init is done).
		case newWithEphemeral(Profile, PrivateHDFactorSource)

		/// The state during onboarding flow until the user has finished
		/// creating her first account. As long as the current state is
		/// `ephemeral`, no data has been persisted into secure storage,
		/// and both the Profile and the private factor source can safely
		/// be discarded.
		case ephemeral(Profile, PrivateHDFactorSource)

		/// When the async Task that loads profile - if any - from secure
		/// storage completes and indeed a profile was found, the state
		/// is changed in to this.
		case persisted(Profile)
	}
}

extension ProfileStore.State {
	fileprivate var profile: Profile {
		switch self {
		case let .newWithEphemeral(profile, _): return profile
		case let .ephemeral(profile, _): return profile
		case let .persisted(profile): return profile
		}
	}
}

// MARK: Private
extension ProfileStore {
	private static func newEphemeral() -> State {
		@Dependency(\.mnemonicClient) var mnemonicClient
		do {
			let mnemonic = try mnemonicClient.generate(BIP39.WordCount.twentyFour, BIP39.Language.english)
			let mnemonicWithPassphrase = MnemonicWithPassphrase(mnemonic: mnemonic)
			let factorSource = try FactorSource.babylon(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				hint: "ephemeral"
			)
			let privateFactorSource = try PrivateHDFactorSource(mnemonicWithPassphrase: mnemonicWithPassphrase, factorSource: factorSource)
			let profile = Profile(factorSource: factorSource)
			return .newWithEphemeral(profile, privateFactorSource)
		} catch {
			let errorMessage = "CRITICAL ERROR, failed to create Mnemonic or FactorSource during init of ProfileStore. Unable to use app: \(String(describing: error))"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			fatalError(errorMessage)
		}
	}

	private func restoreFromSecureStorageIfAble() async {
		@Dependency(\.jsonDecoder) var jsonDecoder
		guard case let .newWithEphemeral(ephemeralProfile, ephemeralPrivateFactorSource) = state else {
			let errorMsg = "Incorrect implementation: `\(#function)` was called when \(Self.self) was in the wrong state, expected state was: 'newWithEphemeral'"
			loggerGlobal.critical(.init(stringLiteral: errorMsg))
			assertionFailure(errorMsg)
			return
		}
		guard
			let existing = try? await secureStorageClient.loadProfile()
		else {
			state = .ephemeral(ephemeralProfile, ephemeralPrivateFactorSource)
			return
		}

		state = .persisted(existing)
	}
}

// MARK: Public
extension ProfileStore {
	public func commitEphemeral() async throws {
		let hint: NonEmptyString
		#if canImport(UIKit)
		@Dependency(\.device) var device
		let deviceModelName = await device.model
		let deviceGivenName = await device.name
		hint = NonEmptyString(rawValue: "\(deviceGivenName) (\(deviceModelName))")!
		#else
		hint = "macOS"
		#endif

		guard case let .ephemeral(ephemeralProfile, ephemeralPrivateFactorSource) = state else {
			let errorMessage = "Incorrect implementation: `\(#function)` was called when \(Self.self) was in the wrong state, expected state was: 'ephemeral'"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
			return
		}

		try await secureStorageClient.saveMnemonicForFactorSource(
			ephemeralPrivateFactorSource.changing(hint: hint) // replace emphemeral hint with device name hint.
		)
		do {
			try await secureStorageClient.saveProfileSnapshot(ephemeralProfile.snapshot())
		} catch {
			let errorMessage = "Critical failure, unable to save profile snapshot: \(String(describing: error))"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			// Unlucky... we earlier successfully managed to save the mnemonic for the factor source, but
			// we failed to save the profile snapshot => tidy up by trying to delete the just saved mnemonic, before
			// we propate the error
			try? await secureStorageClient.deleteMnemonicByFactorSourceID(ephemeralPrivateFactorSource.factorSource.id)
			assertionFailure(errorMessage) // for DEBUG builds we want to crash
			throw error
		}

		state = .persisted(ephemeralProfile)
	}

	public func update(profile: Profile) async throws {
		guard case let .persisted(persistedProfile) = state else {
			let errorMessage = "Incorrect implementation: `\(#function)` was called when \(Self.self) was in the wrong state, expected state was: 'persisted'"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
			return
		}

		guard persistedProfile.id == profile.id else {
			let errorMessage = "Incorrect implementation: `\(#function)` was called with a Profile which UUID does not match the current one. This should never happen."
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
			return
		}

		try await secureStorageClient.saveProfileSnapshot(profile.snapshot())

		state = .persisted(profile)
	}
}
