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
/// implementations of a set of clients (dependencies), namely:
/// * AccountsClient
/// * PersonasClient
/// * AuthorizedDappsClient
/// * AppPreferencesClient (P2PClients)
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
		case newWithEphemeral(EphemeralPrivateProfile)

		/// The state during onboarding flow until the user has finished
		/// creating her first account. As long as the current state is
		/// `ephemeral`, no data has been persisted into secure storage,
		/// and both the Profile and the private factor source can safely
		/// be discarded.
		case ephemeral(EphemeralPrivateProfile)

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
		profileStateSubject.map(\.profile)
			.share() // Multicast
			.eraseToAnyAsyncSequence()
	}

	/// A multicasting replaying async sequence of distinct Profile.
	public func accountValues() async -> AnyAsyncSequence<OnNetwork.Accounts> {
		profileStateSubject.map(\.profile.network.accounts)
			.share() // Multicast
			.eraseToAnyAsyncSequence()
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

		guard case var .ephemeral(ephemeral) = profileStateSubject.value else {
			let errorMessage = "Incorrect implementation: `\(#function)` was called when \(Self.self) was in the wrong state, expected state '\(String(describing: ProfileState.Discriminator.ephemeral))' but was in '\(String(describing: profileStateSubject.value.description))'"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
			return
		}
		ephemeral.update(deviceDescription: deviceDescription)

		do {
			try await secureStorageClient.save(ephemeral: ephemeral)
		} catch {
			let errorMessage = "Critical failure, unable to save profile snapshot: \(String(describing: error))"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			// Unlucky... we earlier successfully managed to save the mnemonic for the factor source, but
			// we failed to save the profile snapshot => tidy up by trying to delete the just saved mnemonic, before
			// we propate the error
			assertionFailure(errorMessage) // for DEBUG builds we want to crash
			throw error
		}

		changeState(to: .persisted(ephemeral.profile))
	}

	public func update(profile: Profile) async throws {
		try await isInitialized() // it should not be possible for us to not be initialized...
		guard profile != profileStateSubject.value.profile else {
			// prevent duplicates
			return
		}

		guard case let .persisted(persistedProfile) = profileStateSubject.value else {
			let errorMessage = "Incorrect implementation: `\(#function)` was called when \(Self.self) was in the wrong state, expected state '\(String(describing: ProfileState.Discriminator.ephemeral))' but was in '\(String(describing: profileStateSubject.value.description))'"
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

		changeState(to: .persisted(profile))
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
		changeState(to: Self.newEphemeral())
	}
}

extension ProfileStore.ProfileState {
	public var description: String {
		discriminator.rawValue
	}

	fileprivate var profile: Profile {
		switch self {
		case let .newWithEphemeral(ephemeral): return ephemeral.profile
		case let .ephemeral(ephemeral): return ephemeral.profile
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

// MARK: Private
extension ProfileStore {
	static func newEphemeral() -> ProfileState {
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
			let ephemeral = EphemeralPrivateProfile(privateFactorSource: privateFactorSource, profile: profile)
			return .newWithEphemeral(ephemeral)
		} catch {
			let errorMessage = "CRITICAL ERROR, failed to create Mnemonic or FactorSource during init of ProfileStore. Unable to use app: \(String(describing: error))"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			fatalError(errorMessage)
		}
	}

	private func restoreFromSecureStorageIfAble() async {
		@Dependency(\.jsonDecoder) var jsonDecoder
		guard case let .newWithEphemeral(ephemeral) = profileStateSubject.value else {
			let errorMsg = "Incorrect implementation: `\(#function)` was called when \(Self.self) was in the wrong state, expected state was: '\(String(describing: ProfileState.Discriminator.newWithEphemeral))' but was in state: '\(String(describing: profileStateSubject.value.discriminator))'"
			loggerGlobal.critical(.init(stringLiteral: errorMsg))
			assertionFailure(errorMsg)
			return
		}
		guard
			let existing = try? await secureStorageClient.loadProfile()
		else {
			changeState(to: .ephemeral(ephemeral))
			return
		}

		changeState(to: .persisted(existing))
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
		case (.ephemeral, .persisted): break // user finished onboarding.
		case (.persisted, .persisted): break // user updated profile, e.g. added another account.
		default:
			let errorMsg = "Incorrect implementation: invalid state transition from '\(String(describing: profileStateSubject.value))' to '\(String(describing: newState))'"
			loggerGlobal.critical(.init(stringLiteral: errorMsg))
			assertionFailure(errorMsg)
			return
		}

		profileStateSubject.send(newState)
	}
}
