import AsyncExtensions
import ClientPrelude
import Cryptography
import Profile
import SecureStorageClient

// MARK: - ProfileStore
public final actor ProfileStore: GlobalActor {
	@Dependency(\.assert) var assert
	@Dependency(\.secureStorageClient) var secureStorageClient

	public static let shared = ProfileStore()

	@_spi(Test)
	public /* inaccessible by SPI */ let state: AsyncCurrentValueSubject<State>

	/// The current value of Profile. Use `update:profile` method to update it. Also see `values`,
	/// for an async sequence of Profile.
	public var profile: Profile { state.value.profile }

	private init() {
		self.state = AsyncCurrentValueSubject<State>(Self.newEphemeral())

		Task {
			await restoreFromSecureStorageIfAble()
		}
	}
}

// MARK: ProfileStore.State
extension ProfileStore {
	/// The different possible states of Profile store. See
	/// `changeState:to` in `ProfileStore` for state machines valid
	/// transitions.
	@_spi(Test)
	public /* inaccessible by SPI */ enum State: Sendable, CustomStringConvertible {
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

extension ProfileStore.State {
	public var description: String {
		switch self {
		case .newWithEphemeral: return "newWithEphemeral"
		case .ephemeral: return "ephemeral"
		case .persisted: return "persisted"
		}
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

extension ProfileStore.State {
	@_spi(Test)
	public enum Disciminator: String, Sendable, Hashable, CustomStringConvertible {
		case newWithEphemeral, ephemeral, persisted
		public var description: String {
			rawValue
		}
	}

	@_spi(Test)
	public var discriminator: Disciminator {
		switch self {
		case .newWithEphemeral: return .newWithEphemeral
		case .ephemeral: return .ephemeral
		case .persisted: return .persisted
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
		guard case let .newWithEphemeral(ephemeral) = state.value else {
			let errorMsg = "Incorrect implementation: `\(#function)` was called when \(Self.self) was in the wrong state, expected state was: '\(String(describing: State.Disciminator.newWithEphemeral))' but was in state: '\(String(describing: state.value.discriminator))'"
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
		if !state.value.isNew {
			return // done
		}
		for await value in state {
			if !value.isNew {
				return // done
			}
			continue
		}
		throw CancellationError()
	}

	private func changeState(to newState: State) {
		switch (state.value, newState) {
		case (.newWithEphemeral, .ephemeral): break // `init` finished, no profile saved.
		case (.newWithEphemeral, .persisted): break // `init` finished, found saved profile.
		case (.ephemeral, .persisted): break // user finished onboarding.
		case (.persisted, .persisted): break // user updated profile, e.g. added another account.
		default:
			let errorMsg = "Incorrect implementation: invalid state transition from '\(String(describing: state.value))' to '\(String(describing: newState))'"
			loggerGlobal.critical(.init(stringLiteral: errorMsg))
			assertionFailure(errorMsg)
			return
		}
		state.send(newState)
	}
}

// MARK: Public
extension ProfileStore {
	/// A multicasting replaying async sequence of distinct Profile.
	public func values() -> AnyAsyncSequence<Profile> {
		state.map(\.profile)
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

		guard case var .ephemeral(ephemeral) = state.value else {
			let errorMessage = "Incorrect implementation: `\(#function)` was called when \(Self.self) was in the wrong state, expected state '\(String(describing: State.Disciminator.ephemeral))' but was in '\(String(describing: state.value.description))'"
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
		guard profile != state.value.profile else {
			// prevent duplicates
			return
		}

		guard case let .persisted(persistedProfile) = state.value else {
			let errorMessage = "Incorrect implementation: `\(#function)` was called when \(Self.self) was in the wrong state, expected state '\(String(describing: State.Disciminator.ephemeral))' but was in '\(String(describing: state.value.description))'"
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
}
