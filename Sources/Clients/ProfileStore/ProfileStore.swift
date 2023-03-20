import AsyncExtensions
import ClientPrelude
import Cryptography
import MnemonicClient
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
/// Internally, the ProfileStore is a state machine which can be either
/// in state`ephemeral` or `persisted`. The former state
/// is used if no ProfileSnapshot was found in `secureStorageClient`,
/// and will trigger the user to perform onboarding in the wallet. If
/// a ProfileSnapshot was found instead the state `persisted` is used.
///
/// The public interface of the ProfileStore is:
///
///     static func shared() async -> ProfileStore
///     func getLoadProfileOutcome() async -> LoadProfileOutcome
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

	private static let _shared = ActorIsolated<ProfileStore?>(nil)
	public static var shared: ProfileStore {
		get async {
			if let shared = await _shared.value {
				return shared
			}
			let shared = await ProfileStore()
			await _shared.setValue(shared)
			return shared
		}
	}

	/// Current Profile
	let profileStateSubject: AsyncCurrentValueSubject<ProfileState>

	init() async {
		self.profileStateSubject = await .init(Self.restoreFromSecureStorageIfAble())
	}
}

// MARK: ProfileStore.ProfileState
extension ProfileStore {
	/// The different possible states of Profile store. See
	/// `changeState:to` in `ProfileStore` for state machines valid
	/// transitions.
	enum ProfileState: Sendable, CustomStringConvertible {
		/// If data was found but failed to deserialize it `loadFailure` will
		/// be present.
		///
		/// The state during onboarding flow until the user has finished
		/// creating her first account. As long as the current state is
		/// `ephemeral`, no data has been persisted into secure storage,
		/// and both the Profile and the private factor source can safely
		/// be discarded.
		case ephemeral(EphemeralProfile)

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

	/// The current network if any
	public func network() async throws -> Profile.Network {
		try profile.onNetwork(id: profile.networkID)
	}

	public var network: Profile.Network? {
		profile.network
	}

	/// A multicasting replaying async sequence of distinct Profile.
	public func values() async -> AnyAsyncSequence<Profile> {
		lens(\.profile)
	}

	/// A multicasting replaying async sequence of distinct Accounts for the currently selected network.
	public func accountValues() async -> AnyAsyncSequence<Profile.Network.Accounts> {
		lens {
			$0.profile.network?.accounts
		}
	}

	/// A multicasting replaying async sequence of distinct FactorSources
	public func factorSourcesValues() async -> AnyAsyncSequence<FactorSources> {
		lens {
			$0.profile.factorSources
		}
	}

	public func getLoadProfileOutcome() async -> LoadProfileOutcome {
		switch self.profileStateSubject.value {
		case .persisted: return .existingProfileLoaded
		case let .ephemeral(ephemeral):
			if let error = ephemeral.loadFailure {
				return .usersExistingProfileCouldNotBeLoaded(failure: error)
			} else {
				return .newUser
			}
		}
	}

	public func importProfileSnapshot(_ profileSnapshot: ProfileSnapshot) async throws {
		try assertProfileStateIsEphemeral()

		guard await (try? secureStorageClient.loadProfileSnapshotData()) == Data?.none else {
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

	public func commitEphemeral() async throws {
		let ephemeral = try assertProfileStateIsEphemeral()

		do {
			try await secureStorageClient.saveProfileSnapshot(profile.snapshot())
		} catch {
			let errorMessage = "Critical failure, unable to save profile snapshot: \(String(describing: error))"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage) // for DEBUG builds we want to crash
			throw error
		}

		changeState(to: .persisted(ephemeral.profile))
	}

	/// if persisted: Updates the in-memomry across app used Profile and also
	/// sync the new value to secure storage (and iCloud if enabled/able).
	///
	/// if ephemeral: Updates the ephemeral profile.
	public func update(profile: Profile) async throws {
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
			// The user is still on onboarding flow, since the Profile has not
			// yet been commited. `update:profile:` was called, meaning some
			// state was added to this ephemeral profile, but user has not
			// yet finished onboarding. The call to `update:profile` might
			// originate from creation of first account, but we do not persist
			// the ephemeral profile until `commitEphemeral` has been called,
			// we do, however, update the ProfileStore's in-memory profile...
			ephemeral.profile = profile

			// ... and then make the update.
			changeState(to: .ephemeral(ephemeral))

		case .persisted:
			try await secureStorageClient.saveProfileSnapshot(profile.snapshot())
			changeState(to: .persisted(profile))
		}
	}

	public func deleteProfile() async throws {
		do {
			try await secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs()
		} catch {
			let errorMessage = "Error, failed to delete profile or factor source, failure: \(String(describing: error))"
			loggerGlobal.error(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
		}
		let ephemeral = await Self.newEphemeralProfile()
		changeState(to: .ephemeral(.init(profile: ephemeral, loadFailure: nil)))
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
		case let .ephemeral(ephemeral): return ephemeral.profile
		case let .persisted(profile): return profile
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
		case .ephemeral: return .ephemeral
		case .persisted: return .persisted
		}
	}
}

// MARK: Internal
extension ProfileStore {
	#if !canImport(UIKit)
	/// used by tests
	internal static let macOSDeviceDescriptionFallback: NonEmptyString = "macOS"
	#endif

	internal static func deviceDescription(
		deviceGivenName: String,
		deviceModel: String
	) -> NonEmptyString {
		"\(deviceGivenName) (\(deviceModel))"
	}
}

// MARK: Private
extension ProfileStore {
	private static func restoreFromSecureStorageIfAble() async -> ProfileState {
		@Dependency(\.jsonDecoder) var jsonDecoder
		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.secureStorageClient) var secureStorageClient

		let loadResult: Swift.Result<Profile?, Profile.LoadingFailure> = await {
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
		}()

		switch loadResult {
		case let .success(.some(existing)):
			return .persisted(existing)
		case .success(.none):
			return await .ephemeral(.init(profile: Self.newEphemeralProfile(), loadFailure: nil))
		case let .failure(loadFailure):
			return await .ephemeral(.init(profile: Self.newEphemeralProfile(), loadFailure: loadFailure))
		}
	}

	private static func newEphemeralProfile() async -> Profile {
		@Dependency(\.mnemonicClient) var mnemonicClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		do {
			let deviceDescription: NonEmptyString
			#if canImport(UIKit)
			@Dependency(\.device) var device
			let deviceGivenName = await device.name
			let deviceModel = await device.model
			deviceDescription = Self.deviceDescription(deviceGivenName: deviceGivenName, deviceModel: deviceModel)
			#else
			deviceDescription = macOSDeviceDescriptionFallback
			#endif

			let mnemonic = try mnemonicClient.generate(BIP39.WordCount.twentyFour, BIP39.Language.english)
			let mnemonicWithPassphrase = MnemonicWithPassphrase(mnemonic: mnemonic)
			let factorSource = try FactorSource.babylon(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				hint: deviceDescription
			)

			// We eagerly save the factor source here because we wanna use the same flow for
			// creation of first account during onboarding like we do from home. This drastically
			// reduces complexity of the app. However, please note that we do NOT persist the
			// profile, since it contains no network yet (no account).
			try await secureStorageClient.saveMnemonicForFactorSource(PrivateHDFactorSource(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				hdOnDeviceFactorSource: .init(factorSource: factorSource)
			))

			loggerGlobal.debug("Created new profile with factorSourceID: \(factorSource.id)")

			return Profile(factorSource: factorSource, creatingDevice: deviceDescription)

		} catch {
			let errorMessage = "CRITICAL ERROR, failed to create Mnemonic or FactorSource during init of ProfileStore. Unable to use app: \(String(describing: error))"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			fatalError(errorMessage)
		}
	}

	private var ephemeral: EphemeralProfile? {
		switch profileStateSubject.value {
		case let .ephemeral(ephemeral): return ephemeral
		case .persisted: return nil
		}
	}

	@discardableResult
	private func assertProfileStateIsEphemeral() throws -> EphemeralProfile {
		struct ExpectedProfileStateToBeEphemeralButItWasNot: Swift.Error {}
		guard let ephemeral else {
			let errorMessage = "Incorrect implementation: `\(#function)` was called when \(Self.self) was in the wrong state, expected state '\(String(describing: ProfileState.Discriminator.ephemeral))' but was in '\(String(describing: profileStateSubject.value.description))'"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
			throw ExpectedProfileStateToBeEphemeralButItWasNot()
		}
		return ephemeral
	}

	@_disfavoredOverload
	private func lens<Property>(
		_ keyPath: KeyPath<ProfileState, Property?>
	) -> AnyAsyncSequence<Property> where Property: Sendable & Equatable {
		lens { $0[keyPath: keyPath] }
	}

	private func lens<Property>(
		_ keyPath: KeyPath<ProfileState, Property>
	) -> AnyAsyncSequence<Property> where Property: Sendable & Equatable {
		lens { $0[keyPath: keyPath] }
	}

	private func lens<Property>(
		_ map: @escaping @Sendable (ProfileState) -> Property?
	) -> AnyAsyncSequence<Property> where Property: Sendable & Equatable {
		profileStateSubject.compactMap { map($0) }
			.share() // Multicast
			.eraseToAnyAsyncSequence()
	}

	private func changeState(to newState: ProfileState) {
		profileStateSubject.send(newState)
	}
}

// MARK: - EphemeralProfile
struct EphemeralProfile: Sendable, Hashable {
	var profile: Profile
	/// If this during startup an earlier Profile was found but we failed to load it.
	let loadFailure: Profile.LoadingFailure?
}
