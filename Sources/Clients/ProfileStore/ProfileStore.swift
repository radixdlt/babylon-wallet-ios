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
	@Dependency(\.userDefaultsClient) var userDefaultsClient

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
		try profile.network(id: profile.networkID)
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

	/// A multicasting replaying async sequence of distinct Personas for the currently selected network.
	public func personaValues() -> AnyAsyncSequence<Profile.Network.Personas> {
		lens {
			$0.profile.network?.personas
		}
	}

	/// A multicasting replaying async sequence of distinct Gateways
	public func gatewaysValues() async -> AnyAsyncSequence<Gateways> {
		lens {
			$0.profile.appPreferences.gateways
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
		case .persisted:
			return .existingProfile
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

		guard await (try? secureStorageClient.loadProfileSnapshotData(profile.header.id)) == Data?.none else {
			struct ExistingProfileSnapshotFoundAbortingImport: Swift.Error {}
			throw ExistingProfileSnapshotFoundAbortingImport()
		}

		do {
			try await changeProfileSnapshot(to: profileSnapshot)
		} catch {
			let errorMessage = "Critical failure, unable to save imported profile snapshot: \(String(describing: error))"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage) // for DEBUG builds we want to crash
			throw error
		}
	}

	public func importCloudProfileSnapshot(_ header: ProfileSnapshot.Header) async throws {
		try assertProfileStateIsEphemeral()

		do {
			// Load the snapshot, also this will validate if the snapshot actually exist
			let profileSnapshot = try await secureStorageClient.loadProfileSnapshot(header.id)
			guard let profileSnapshot else {
				struct FailedToLoadProfile: Swift.Error {}
				throw FailedToLoadProfile()
			}
			try await changeProfileSnapshot(to: profileSnapshot)
		} catch {
			let errorMessage = "Critical failure, unable to save imported profile snapshot: \(String(describing: error))"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage) // for DEBUG builds we want to crash
			throw error
		}
	}

	public func commitEphemeral() async throws {
		let ephemeral = try assertProfileStateIsEphemeral()
		try await changeProfileSnapshot(to: ephemeral.profile.snapshot())
	}

	/// If persisted: updates the in-memomry across-the-app-used Profile and also
	/// sync the new value to secure storage (and iCloud if enabled/able).
	///
	/// if ephemeral: Updates the ephemeral profile.
	public func update(profile: Profile) async throws {
		guard profile != profileStateSubject.value.profile else {
			// prevent duplicates
			return
		}
		guard self.profile.header.id == profile.header.id else {
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
			try await saveProfileChanges(profile)
		}
	}

	public func deleteProfile(keepIcloudIfPresent: Bool) async throws {
		// Assert that this device is allowed to make changes on Profile
		try await checkIfProfileIsOwnedByTheDevice()

		do {
			await userDefaultsClient.removeActiveProfileId()
			try await secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs(profile.header.id, true)
		} catch {
			let errorMessage = "Error, failed to delete profile or factor source, failure: \(String(describing: error))"
			loggerGlobal.error(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
		}
		let ephemeral = await Self.newEphemeralProfile()
		changeState(to: .ephemeral(.init(profile: ephemeral, loadFailure: nil)))
	}
}

extension ProfileStore {
	// Changes the currently used ProfileSnapshot, usually to one from a backup or to one just created.
	func changeProfileSnapshot(to profileSnapshot: ProfileSnapshot) async throws {
		var profileSnapshot = profileSnapshot
		await claimProfileSnapshot(&profileSnapshot)

		// Save the update snapshot.
		// Do not check the ownership since the device did claim the profile ownership
		try await saveProfileSnapshot(profileSnapshot, checkOwnership: false)
		// Update to new active profile id, so it is used from now on.
		await userDefaultsClient.setActiveProfileId(profileSnapshot.header.id)

		// Update the state with the imported snapshot
		try changeState(to: .persisted(.init(snapshot: profileSnapshot)))
	}

	/// Claim the profile by updating **lastUsedOnDevice**
	func claimProfileSnapshot(_ snapshot: inout ProfileSnapshot) async {
		@Dependency(\.device) var device
		let description = await NonEmptyString(rawValue: "\(device.name) (\(device.model))")!
		let deviceInfo = await Self.createDeviceInfo(description)
		snapshot.header.lastUsedOnDevice = deviceInfo
	}

	func saveProfileChanges(_ profile: Profile) async throws {
		var profile = profile
		updateHeader(&profile)
		try await saveProfileSnapshot(profile.snapshot())
		changeState(to: .persisted(profile))
	}

	/// Update the header with all of the relevant changes
	func updateHeader(_ profile: inout Profile) {
		@Dependency(\.date) var date
		let networks = profile.networks

		profile.header.lastModified = date.now
		profile.header.contentHint.numberOfNetworks = networks.count
		profile.header.contentHint.numberOfAccountsOnAllNetworksInTotal = networks.values.reduce(0) { partialResult, network in
			partialResult + network.accounts.count
		}
		profile.header.contentHint.numberOfPersonasOnAllNetworksInTotal = networks.values.reduce(0) { partialResult, network in
			partialResult + network.personas.count
		}
	}

	/// Commit the snapshot changes
	func saveProfileSnapshot(_ snapshot: ProfileSnapshot, checkOwnership: Bool = true) async throws {
		if checkOwnership {
			// Assert that this device is allowed to make changes on Profile
			try await checkIfProfileIsOwnedByTheDevice()
		}

		// Always update the header along with the snapshot itelf,
		// so we are sure that the Header in Snapshot is synced with the Header in the HeadersList
		try await updateProfileHeadersList(snapshot.header)
		try await secureStorageClient.saveProfileSnapshot(snapshot)
	}

	func checkIfProfileIsOwnedByTheDevice() async throws {
		/// The device is allowed to make CRUD operations on the profile only if it is the last used device
		if let lastUsedOnDevice = try await secureStorageClient.loadProfileSnapshot(profile.header.id)?.header.lastUsedOnDevice {
			let deviceId = await Self.getDeviceId()
			guard lastUsedOnDevice.id == deviceId else {
				// Note: We do not reset the active profile id, as doing so, will imply that user has no profile.
				//       Instead, we will prompt that the user, that the currently active profile is used on other device.
				let error = Profile.ProfileIsUsedOnAnotherDeviceError(lastUsedOnDevice: lastUsedOnDevice)
				// Go to ephemeral state straightaway. The Wallet will redirect user to the Onboarding screen.
				await changeState(to: .ephemeral(.init(
					profile: Self.newEphemeralProfile(),
					loadFailure: .profileUsedOnAnotherDevice(error)
				)))
				throw error
			}
		}
	}

	func updateProfileHeadersList(_ header: ProfileSnapshot.Header) async throws {
		if var profileHeaders = try await secureStorageClient.loadProfileHeaderList()?.rawValue {
			profileHeaders[id: header.id] = header
			try await secureStorageClient.saveProfileHeaderList(.init(rawValue: profileHeaders)!)
		} else {
			try await secureStorageClient.saveProfileHeaderList(.init(rawValue: [header])!)
		}
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
	internal static let macOSDeviceDescriptionFallback: FactorSource.Description = "macOS"
	internal static let macOSDeviceLabelFallback: FactorSource.Label = "macOS"
	#endif

	internal static func deviceDescription(
		label: FactorSource.Label,
		description: FactorSource.Description
	) -> NonEmptyString {
		"\(label.rawValue) (\(description.rawValue))"
	}
}

// MARK: Private
extension ProfileStore {
	private static func restoreFromSecureStorageIfAble() async -> ProfileState {
		@Dependency(\.jsonDecoder) var jsonDecoder
		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaultsClient) var userDefaultsClient

		let loadResult: Swift.Result<Profile?, Profile.LoadingFailure> = await {
			guard let profileId = userDefaultsClient.activeProfileId() else {
				return .success(nil)
			}

			guard
				let profileSnapshotData = try? await secureStorageClient.loadProfileSnapshotData(profileId)
			else {
				return .success(nil)
			}

			let decodedHeader: ProfileSnapshot.Header
			do {
				// Implement decode version
				decodedHeader = try ProfileSnapshot.Header.fromJSON(
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

			guard await decodedHeader.lastUsedOnDevice.id == Self.getDeviceId() else {
				return .failure(.profileUsedOnAnotherDevice(.init(lastUsedOnDevice: decodedHeader.lastUsedOnDevice)))
			}

			do {
				try decodedHeader.validateCompatibility()
			} catch {
				// Incompatible Versions
				return .failure(.profileVersionOutdated(
					json: profileSnapshotData,
					version: decodedHeader.snapshotVersion
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
			let label: FactorSource.Label
			let description: FactorSource.Description
			#if canImport(UIKit)
			@Dependency(\.device) var device
			/// we use name as label and model as description
			let deviceName = await device.name
			let deviceModel = await device.model
			label = .init(rawValue: deviceName)
			description = .init(rawValue: deviceModel)
			#else
			label = macOSDeviceLabelFallback
			description = macOSDeviceDescriptionFallback
			#endif

			let mnemonic = try mnemonicClient.generate(BIP39.WordCount.twentyFour, BIP39.Language.english)
			let mnemonicWithPassphrase = MnemonicWithPassphrase(mnemonic: mnemonic)
			let factorSource = try FactorSource.babylon(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				label: label,
				description: description
			)

			// We eagerly save the factor source here because we wanna use the same flow for
			// creation of first account during onboarding like we do from home. This drastically
			// reduces complexity of the app. However, please note that we do NOT persist the
			// profile, since it contains no network yet (no account).
			try await secureStorageClient.saveMnemonicForFactorSource(PrivateHDFactorSource(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				hdOnDeviceFactorSource: factorSource.hdOnDeviceFactorSource
			))

			loggerGlobal.debug("Created new profile with factorSourceID: \(factorSource.id)")

			@Dependency(\.date) var dateGenerator
			@Dependency(\.uuid) var uuid

			let date = dateGenerator.now
			let deviceDescription = deviceDescription(label: label, description: description)
			let deviceInfo = await createDeviceInfo(deviceDescription)

			let header = ProfileSnapshot.Header(
				creatingDevice: deviceInfo,
				lastUsedOnDevice: deviceInfo, // Whe creating the Profile the lastUsedOnDevice is the same as creatingDevice
				id: uuid(),
				creationDate: date,
				lastModified: date,
				contentHint: .init() // Empty initially
			)

			return Profile(header: header, factorSources: .init(factorSource.factorSource))

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

extension ProfileStore {
	static func createDeviceInfo(_ deviceDescription: NonEmptyString) async -> ProfileSnapshot.Header.UsedDeviceInfo {
		@Dependency(\.date) var dateGenerator
		let date = dateGenerator.now

		return await ProfileSnapshot.Header.UsedDeviceInfo(
			description: deviceDescription,
			id: getDeviceId(),
			date: date
		)
	}

	static func getDeviceId() async -> ProfileSnapshot.Header.UsedDeviceInfo.ID {
		@Dependency(\.userDefaultsClient) var userDefaults

		guard let deviceId = userDefaults.getDeviceId() else {
			@Dependency(\.uuid) var uuid

			let deviceId = uuid()
			await userDefaults.setDeviceId(deviceId)
			return deviceId
		}

		return deviceId
	}
}

// MARK: - EphemeralProfile
struct EphemeralProfile: Sendable, Hashable {
	var profile: Profile
	/// If this during startup an earlier Profile was found but we failed to load it.
	let loadFailure: Profile.LoadingFailure?
}

extension UserDefaultsClient {
	static let activeProfileId = "profile.activeProfileID"
	static let deviceId = "profile.deviceID"

	enum ActiveProfileIdErrors: Error {
		case noActiveProfileId
		case invalidActiveProfileId
	}

	func activeProfileId() -> ProfileSnapshot.Header.ID? {
		stringForKey(Self.activeProfileId)
			.flatMap {
				.init(uuidString: $0)
			}
	}

	func getDeviceId() -> ProfileSnapshot.Header.UsedDeviceInfo.ID? {
		stringForKey(Self.deviceId)
			.flatMap {
				.init(uuidString: $0)
			}
	}

	func setDeviceId(_ id: UUID) async {
		await setString(id.uuidString, Self.deviceId)
	}

	func setActiveProfileId(_ id: ProfileSnapshot.Header.UsedDeviceInfo.ID) async {
		await setString(id.uuidString, Self.activeProfileId)
	}

	func removeActiveProfileId() async {
		await remove(Self.activeProfileId)
	}
}
