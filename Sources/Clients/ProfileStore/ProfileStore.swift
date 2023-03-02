import AsyncExtensions
import ClientPrelude
import Cryptography
import Profile
import SecureStorageClient

// MARK: - ProfileStore
/// An in-memory store for the `Profile` providing thread safe
/// read and write access to the wallets profile. Every write
/// of the profile is protected agaist data races thanks to
/// the actor model and every write persists it in keychain
/// and if user has enabled: the keychain item syncs to iCloud
/// as well.
///
/// This actor is meant **not** meant to be used directly by the
/// apps reducers, but rather always indirectly, via the live
/// implementations of a set of clients (dependencies), e.g.:
/// * AccountsClient
/// * PersonasClient
/// * AuthorizedDappsClient
/// * AppPreferencesClient
///
/// These live implementaions will all references the one and only
/// ProfileStore singleton instance `shared`.
///
/// Internally, the ProfileStore is a state machine starting during
/// init in a first state `new`, then `async` (within a `Task`), it
/// transitions to either `ephemeral` or `persisted`. The former state
/// is used if no ProfileSnapshot was found in `secureStorageClient`,
/// and will trigger the user to perform onboarding in the wallet. If
/// a ProfileSnapshot was found instead the state `persisted` is used.
///
/// The public interface of the ProfileStore is:
///
///     static let shared: ProfileStore
///     var profile: Profile (async)
///     func values() -> AnyAsyncSequence<Profile>
///     func commitEphemeral() async throws
///     func deleteProfile() async throws
///     func update(profile: Profile) async throws
///     func importProfileSnapshot(:ProfileSnapshot) async throws
///
///
public final actor ProfileStore {
	@Dependency(\.assertionFailure) var assertionFailure
	@Dependency(\.secureStorageClient) var secureStorageClient

	public static let shared = ProfileStore()

	/// Current Profile
	let profileStateSubject: AsyncCurrentValueSubject<ProfileState>

	init(
		profileStateSubject: AsyncCurrentValueSubject<ProfileState>
	) {
		self.profileStateSubject = profileStateSubject

		Task {
			await restoreFromSecureStorageIfAble()
		}
	}

	init() {
		self.init(
			profileStateSubject: AsyncCurrentValueSubject<ProfileState>(Self.newEphemeral())
		)
	}
}

// MARK: ProfileStore.ProfileState
extension ProfileStore {
	/// The different possible states of Profile store. See
	/// `changeState:to` in `ProfileStore` for state machines valid
	/// transitions.
	enum ProfileState: Sendable, CustomStringConvertible {
		/// The initial state, set during start of init, have not yet
		/// checked Secure Storage for an potentially existing stored
		/// profile, which require an async Task to be done at end of
		/// init (which will complete after init is done).
		case newWithEphemeral(Profile.Ephemeral.Private)

		/// If data was found but failed to deserialize it `loadFailure` will
		/// be present.
		///
		/// The state during onboarding flow until the user has finished
		/// creating her first account. As long as the current state is
		/// `ephemeral`, no data has been persisted into secure storage,
		/// and both the Profile and the private factor source can safely
		/// be discarded.
		case ephemeral(Profile.Ephemeral)

		/// When the async Task that loads profile - if any - from secure
		/// storage completes and indeed a profile was found, the state
		/// is changed in to this.
		case persisted(Profile)
	}
}

// MARK: Public
extension ProfileStore {
	/// The current value of Profile. Use `update:profile` method to update it. Also see `values`,
	/// for an async sequence of Profile.
	public var profile: Profile { profileStateSubject.value.profile }

	/// The current network with a non empty set of accounts.
	public var network: OnNetwork { profile.network }

	/// A multicasting replaying async sequence of distinct Profile.
	public func values() async -> AnyAsyncSequence<Profile> {
		lens(\.profile)
	}

	/// A multicasting replaying async sequence of distinct Accounts for the currently selected network.
	public func accountValues() async -> AnyAsyncSequence<OnNetwork.Accounts> {
		lens(\.profile.network.accounts)
	}

	public func getEphemeral() async -> Profile.Ephemeral? {
		try? await isInitialized()
		return self.ephemeral
	}

	public func importProfileSnapshot(_ profileSnapshot: ProfileSnapshot) async throws {
		try await isInitialized()
		try assertProfileStateIsEphemeral()
		guard (try? await secureStorageClient.loadProfileSnapshotData()) == Data?.none else {
			struct ExistingProfileSnapshotFoundAbortingImport: Swift.Error {}
			throw ExistingProfileSnapshotFoundAbortingImport()
		}
		let profile = try Profile(snapshot: profileSnapshot)
		do {
			try await secureStorageClient.saveProfileSnapshot(profileSnapshot)
		} catch {
			let errorMessage = "Critical failure, unable to save imported profile snapshot: \(String(describing: error))"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage) // for DEBUG builds we want to crash
			throw error
		}
		changeState(to: .persisted(profile))
	}

	@discardableResult
	private func assertProfileStateIsEphemeral() throws -> Profile.Ephemeral {
		struct ExpectedProfileStateToBeEphemeralButItWasNot: Swift.Error {}
		guard let ephemeral else {
			let errorMessage = "Incorrect implementation: `\(#function)` was called when \(Self.self) was in the wrong state, expected state '\(String(describing: ProfileState.Discriminator.ephemeral))' but was in '\(String(describing: profileStateSubject.value.description))'"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
			throw ExpectedProfileStateToBeEphemeralButItWasNot()
		}
		return ephemeral
	}

	public func commitEphemeral() async throws {
		try await isInitialized()

		let deviceDescription: NonEmptyString
		#if canImport(UIKit)
		@Dependency(\.device) var device
		let deviceModelName = await device.model
		let deviceGivenName = await device.name
		deviceDescription = NonEmptyString(rawValue: "\(deviceGivenName) (\(deviceModelName))")!
		#else
		deviceDescription = "macOS"
		#endif

		var ephemeral = try assertProfileStateIsEphemeral()
		ephemeral.update(deviceDescription: deviceDescription)

		do {
			try await secureStorageClient.save(ephemeral: ephemeral.private)
		} catch {
			let errorMessage = "Critical failure, unable to save profile snapshot: \(String(describing: error))"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage) // for DEBUG builds we want to crash
			throw error
		}

		changeState(to: .persisted(ephemeral.private.profile))
	}

	/// if persisted: Updates the in-memomry across app used Profile and also
	/// sync the new value to secure storage (and iCloud if enabled/able).
	///
	/// if ephemeral: Updates the ephemeral profile.
	public func update(profile: Profile) async throws {
		try await isInitialized() // it should not be possible for us to not be initialized...
		guard profile != profileStateSubject.value.profile else {
			// prevent duplicates
			return
		}
		guard self.profile.id == profile.id else {
			let errorMessage = "Incorrect implementation: `\(#function)` was called with a Profile which UUID does not match the current one. This should never happen."
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
			return
		}

		switch profileStateSubject.value {
		case var .ephemeral(ephemeral):
			// E.g. Creation of first Account during onboarding flow
			// we will not persist in secureStorage, nor change state from `.ephemeral`,
			// but we will update the in memory epheral profile
			ephemeral.updateProfile(profile)
			changeState(to: .ephemeral(ephemeral))

		case .persisted:
			try await secureStorageClient.saveProfileSnapshot(profile.snapshot())
			changeState(to: .persisted(profile))

		case .newWithEphemeral: fatalError("should not be possible, we await `isInitialized` in top.")
		}
	}

	public func deleteProfile() async throws {
		try await isInitialized() // it should not be possible for us to not be initialized...
		do {
			try await secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs()
		} catch {
			let errorMessage = "Error, failed to delete profile or factor source, failure: \(String(describing: error))"
			loggerGlobal.error(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
		}
		changeState(to: .ephemeral(.init(private: Self.newEphemeralProfile(), loadFailure: nil)))
	}
}

// MARK: Sugar (Public)
extension ProfileStore {
	/// Syntactic sugar for:
	///     var profile = await profileStore.profile
	///     mutateProfile(&profile)
	///     try await profileStore.update(profile: profile)
	public func updating<T>(
		_ mutateProfile: @Sendable (inout Profile) async throws -> T
	) async throws -> T {
		var copy = profile
		let result = try await mutateProfile(&copy)
		try await update(profile: copy)
		return result // in many cases `Void`.
	}
}

extension ProfileStore.ProfileState {
	public var description: String {
		discriminator.rawValue
	}

	fileprivate var profile: Profile {
		switch self {
		case let .newWithEphemeral(ephemeral): return ephemeral.profile
		case let .ephemeral(ephemeral): return ephemeral.private.profile
		case let .persisted(profile): return profile
		}
	}

	fileprivate var isNew: Bool {
		switch self {
		case .newWithEphemeral: return true
		case .ephemeral, .persisted: return false
		}
	}
}

extension ProfileStore.ProfileState {
	enum Discriminator: String, Sendable, Hashable, CustomStringConvertible {
		case newWithEphemeral, ephemeral, persisted
		public var description: String {
			rawValue
		}
	}

	var discriminator: Discriminator {
		switch self {
		case .newWithEphemeral: return .newWithEphemeral
		case .ephemeral: return .ephemeral
		case .persisted: return .persisted
		}
	}
}

// MARK: Internal (for tests)
extension ProfileStore {
	internal static func newEphemeral() -> ProfileState {
		.newWithEphemeral(Self.newEphemeralProfile())
	}

	internal static func newEphemeralProfile() -> Profile.Ephemeral.Private {
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
			return Profile.Ephemeral.Private(privateFactorSource: privateFactorSource, profile: profile)
		} catch {
			let errorMessage = "CRITICAL ERROR, failed to create Mnemonic or FactorSource during init of ProfileStore. Unable to use app: \(String(describing: error))"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			fatalError(errorMessage)
		}
	}
}

// MARK: Private
extension ProfileStore {
	private var ephemeral: Profile.Ephemeral? {
		switch profileStateSubject.value {
		case let .ephemeral(ephemeral): return ephemeral
		case .newWithEphemeral, .persisted: return nil
		}
	}

	private func lens<Property>(
		_ keyPath: KeyPath<ProfileState, Property>
	) -> AnyAsyncSequence<Property> where Property: Sendable & Equatable {
		profileStateSubject.map { $0[keyPath: keyPath] }
			.share() // Multicast
			.eraseToAnyAsyncSequence()
	}

	private func restoreFromSecureStorageIfAble() async {
		@Dependency(\.jsonDecoder) var jsonDecoder
		@Dependency(\.errorQueue) var errorQueue

		guard case let .newWithEphemeral(ephemeral) = profileStateSubject.value else {
			let errorMsg = "Incorrect implementation: `\(#function)` was called when \(Self.self) was in the wrong state, expected state was: '\(String(describing: ProfileState.Discriminator.newWithEphemeral))' but was in state: '\(String(describing: profileStateSubject.value.discriminator))'"
			loggerGlobal.critical(.init(stringLiteral: errorMsg))
			assertionFailure(errorMsg)
			return
		}

		@Sendable func load() async -> Swift.Result<Profile?, Profile.LoadingFailure> {
			guard
				let profileSnapshotData = try? await secureStorageClient.loadProfileSnapshotData()
			else {
				return .success(nil)
			}

			let decodedVersion: ProfileSnapshot.Version
			do {
				decodedVersion = try ProfileSnapshot.Version.fromJSON(
					data: profileSnapshotData,
					jsonDecoder: jsonDecoder()
				)
			} catch {
				return .failure(
					.decodingFailure(
						json: profileSnapshotData,
						.known(.noProfileSnapshotVersionFoundInJSON
						)
					)
				)
			}

			do {
				try ProfileSnapshot.validateCompatibility(version: decodedVersion)
			} catch {
				// Incompatible Versions
				return .failure(.profileVersionOutdated(
					json: profileSnapshotData,
					version: decodedVersion
				))
			}

			let profileSnapshot: ProfileSnapshot
			do {
				profileSnapshot = try jsonDecoder().decode(ProfileSnapshot.self, from: profileSnapshotData)
			} catch let decodingError as Swift.DecodingError {
				return .failure(.decodingFailure(
					json: profileSnapshotData,
					.known(.decodingError(.init(decodingError: decodingError)))
				)
				)
			} catch {
				return .failure(.decodingFailure(
					json: profileSnapshotData,
					.unknown(.init(error: error))
				))
			}

			let profile: Profile
			do {
				profile = try Profile(snapshot: profileSnapshot)
			} catch {
				return .failure(.failedToCreateProfileFromSnapshot(
					.init(
						version: profileSnapshot.version,
						error: error
					))
				)
			}

			return .success(profile)
		}

		@Sendable func newState(from loadProfileResult: Swift.Result<Profile?, Profile.LoadingFailure>) -> ProfileState {
			switch loadProfileResult {
			case let .success(.some(existing)):
				return .persisted(existing)
			case .success(.none):
				return .ephemeral(.init(private: ephemeral, loadFailure: nil))
			case let .failure(loadFailure):
				return .ephemeral(.init(private: ephemeral, loadFailure: loadFailure))
			}
		}

		let newState = await newState(from: load())
		changeState(to: newState)
	}

	private func isInitialized() async throws {
		if !profileStateSubject.value.isNew {
			return // done
		}
		for await value in profileStateSubject {
			if !value.isNew {
				return // done
			}
			continue
		}
		throw CancellationError()
	}

	private func changeState(to newState: ProfileState) {
		switch (profileStateSubject.value, newState) {
		case (.newWithEphemeral, .ephemeral): break // `init` finished, no profile saved.
		case (.newWithEphemeral, .persisted): break // `init` finished, found saved profile.
		case (.ephemeral, .ephemeral): break // user created first account during onboarding
		case (.ephemeral, .persisted): break // user finished onboarding.
		case (.persisted, .persisted): break // user updated profile, e.g. added another account.
		case (.persisted, .ephemeral): break // user deleted wallet from settings
		default:
			let errorMsg = "Incorrect implementation: invalid state transition from '\(String(describing: profileStateSubject.value))' to '\(String(describing: newState))'"
			loggerGlobal.critical(.init(stringLiteral: errorMsg))
			assertionFailure(errorMsg)
			return
		}

		profileStateSubject.send(newState)
	}
}
