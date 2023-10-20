// MARK: - ProfileStore
public final actor ProfileStore {
	@Dependency(\.assertionFailure) var assertionFailure
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.userDefaultsClient) var userDefaultsClient

	public static let shared = ProfileStore()

	/// Current Profile
	private let profileStateSubject: AsyncCurrentValueSubject<Profile>

	// Replay since can a conflict can be emitted from the ProfileStore initializer
	// and must be buffered.
	typealias OwnershipConflictSubject = AsyncReplaySubject<OwnershipConflict>

	private let ownershipConflictSubject: OwnershipConflictSubject = .init(bufferSize: 1)

	private let onboardingNeededSubject: AsyncPassthroughSubject<DeletedProfileOrigin> = .init()

	/// Only mutable since we need to update the description with async, since reading
	/// device model and name is async.
	private var deviceInfo: DeviceInfo

	init() {
		let metaDeviceInfo = Self._deviceInfo()
		let stuff = Self._loadSavedElseNewProfile(metaDeviceInfo: metaDeviceInfo)
		self.deviceInfo = stuff.deviceInfo
		self.profileStateSubject = AsyncCurrentValueSubject(stuff.profile)

		if let conflictingOwners = stuff.conflictingOwners {
			// Actor-isolated instance method ',,' can not be referenced from
			// a non-isolated context; this is an error in Swift 6
			// hmm... we might wrap this in a Task, not too bad.
			self.emitOwnershipConflict(ownerOfCurrentProfile: conflictingOwners.ownerOfCurrentProfile)
		}
	}
}

// MARK: - DeletedProfileOrigin
public enum DeletedProfileOrigin: Sendable, Hashable {
	case ownershipConflict
	case manuallyFromSettings
}

// MARK: - ConflictingOwners
public struct ConflictingOwners: Sendable, Hashable {
	public let ownerOfCurrentProfile: DeviceInfo
	public let thisDevice: DeviceInfo
}

// MARK: - OwnershipConflict
public struct OwnershipConflict: Sendable {
	public let conflictingOwners: ConflictingOwners

	public enum ConflictResolutionByUser: Sendable, Hashable {
		case reclaimProfileOnThisDevice
		case deleteProfileOnThisDevice
	}

	public typealias OnConflictResolutionByUser = @Sendable (ConflictResolutionByUser) async throws -> Void

	public let onConflictResolutionByUser: OnConflictResolutionByUser
}

extension OwnershipConflict {
	init(
		ownerOfCurrentProfile: DeviceInfo,
		thisDevice: DeviceInfo,
		onConflictResolutionByUser: @escaping OnConflictResolutionByUser
	) {
		self.init(
			conflictingOwners: .init(
				ownerOfCurrentProfile: ownerOfCurrentProfile,
				thisDevice: thisDevice
			),
			onConflictResolutionByUser: onConflictResolutionByUser
		)
	}
}

// MARK: Public
extension ProfileStore {
	/// The current value of Profile. Use `update:profile` method to update it. Also see `values`,
	/// for an async sequence of Profile.
	public var profile: Profile {
		profileStateSubject.value
	}

	/// Mutates the in-memory copy of the Profile usung `transform`, and saves a
	/// snapshot of it profile into Keychain (after having updated its header)
	/// - Parameter transform: A mutating transform updating the profile.
	/// - Returns: The result of the transform, often this might be `Void`.
	public func updating<T: Sendable>(
		_ transform: @Sendable (inout Profile) async throws -> T
	) async throws -> T {
		var updated = profile
		let result = try await transform(&updated)
		try saveProfileAfterUpdateItsHeader(updated)
		return result // in many cases `Void`.
	}

	/// Looks up a ProfileSnapshot for the given `header` and tries to import it,
	/// updates `headerList` (Keychain),  `activeProfileID` (UserDefaults)
	/// and saves the snapshot of the profile into Keychain.
	/// - Parameter profile: Imported Profile to use and save.
	public func importCloudProfileSnapshot(_ header: ProfileSnapshot.Header) throws {
		do {
			// Load the snapshot, also this will validate if the snapshot actually exist
			let profileSnapshot = try secureStorageClient.loadProfileSnapshot(header.id)
			guard let profileSnapshot else {
				struct FailedToLoadProfile: Swift.Error {}
				throw FailedToLoadProfile()
			}
			try importProfileSnapshot(profileSnapshot)
		} catch {
			let errorMessage = "Critical failure, unable to save imported profile snapshot: \(String(describing: error))"
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage) // for DEBUG builds we want to crash
			throw error
		}
	}

	/// Change current profile to new imported profle snapshot and saves it, by
	/// updates `headerList` (Keychain),  `activeProfileID` (UserDefaults)
	/// and saves the snapshot of the profile into Keychain.
	/// - Parameter profile: Imported Profile to use and save.
	public func importProfileSnapshot(_ snapshot: ProfileSnapshot) throws {
		try importProfile(Profile(snapshot: snapshot))
	}

	/// Change current profile to new importedProfile and saves it, by
	/// updates `headerList` (Keychain),  `activeProfileID` (UserDefaults)
	/// and saves a snapshot of the profile into Keychain.
	/// - Parameter profile: Imported Profile to use and save.
	public func importProfile(_ profile: Profile) throws {
		try saveProfileAfterUpdateItsHeader(profile)
	}

	public func deleteProfile(keepInICloudIfPresent: Bool) throws {
		// Assert that this device is allowed to make changes on Profile
		try _assertOwnership()

		do {
			userDefaultsClient.removeActiveProfileID()
			try secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs(profile.header.id, keepInICloudIfPresent)
		} catch {
			let errorMessage = "Error, failed to delete profile or factor source, failure: \(String(describing: error))"
			loggerGlobal.error(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
		}

		let profile = try! Self._tryGenerateAndSaveNewProfile(deviceInfo: deviceInfo)
		self.profileStateSubject.send(profile)
		self.onboardingNeededSubject.send(.manuallyFromSettings)
	}

	public func finishedOnboarding() {
		fatalError()
	}
}

// MARK: - ProfileStore.Error
extension ProfileStore {
	public enum Error: String, Swift.Error, Equatable {
		case profileIDMismatch
		case profileUsedOnAnotherDevice
	}
}

// MARK: "Private"
extension ProfileStore {
	func _lens<Property>(
		_ transform: @escaping @Sendable (Profile) -> Property?
	) -> AnyAsyncSequence<Property> where Property: Sendable & Equatable {
		profileStateSubject.compactMap(transform)
			.share() // Multicast
			.removeDuplicates()
			.eraseToAnyAsyncSequence()
	}
}

// MARK: Private
extension ProfileStore {
	/// Asserts identity and ownership of a profile, then updates its header, saves it and emits an update.
	/// - Parameter updated: Profile to save (after updating its header).
	private func saveProfileAfterUpdateItsHeader(_ updated: Profile) throws {
		guard updated != profile else { return } // prevent duplicates

		try _assertIdentity(of: updated)

		// Must not update a Profile owned by another device
		try _assertOwnership(of: updated)

		var updated = updated
		try _updateHeader(of: &updated)
		try _saveProfileAndEmitUpdate(updated)
	}
}

// MARK: Helpers
extension ProfileStore {
	/// Updates the `lastUsedOnDevice` to use this device, on `profile`,
	/// then saves this profile and emits an update.
	/// - Parameter profile: Profile to update `lastUsedOnDevice` of and
	/// save on this device.
	private func claimOwnershipOfProfile() throws {
		var copy = profile
		try _claimOwnership(of: &copy)
	}

	/// Updates the `lastUsedOnDevice` to use this device, on `profile`,
	/// then saves this profile and emits an update.
	/// - Parameter profile: Profile to update `lastUsedOnDevice` of and
	/// save on this device.
	private func _claimOwnership(of profile: inout Profile) throws {
		@Dependency(\.date) var date
		profile.header.lastUsedOnDevice = deviceInfo
		profile.header.lastUsedOnDevice.date = date()
		try _saveProfileAndEmitUpdate(profile)
	}

	/// Updates the header of a Profile, lastModified date, contentHint etc.
	/// - Parameter profile: Profile with a header to update
	private func _updateHeader(of profile: inout Profile) throws {
		@Dependency(\.date) var date
		let networks = profile.networks

		profile.header.lastModified = date.now
		profile.header.contentHint.numberOfNetworks = networks.count
		profile.header.contentHint.numberOfAccountsOnAllNetworksInTotal = networks.values.map(\.accounts.count).reduce(0, +)
		profile.header.contentHint.numberOfPersonasOnAllNetworksInTotal = networks.values.map(\.personas.count).reduce(0, +)
	}

	/// Updates the in-memory copy of profile in ProfileStores and saves it, by
	/// updates `headerList` (Keychain),  `activeProfileID` (UserDefaults)
	/// and saves a snapshot of the profile into Keychain.
	/// - Parameter profile: Profile to save
	private func _saveProfileAndEmitUpdate(_ profile: Profile) throws {
		profileStateSubject.send(profile)
		try Self._save(profile: profile)
	}

	/// Asserts that the **identity** of `profile` matches that of `self.profile`, which
	/// is not using Equality but rather a UUID check.
	///
	/// This does NOT check ownership, for that see: `_assertOwnership:of`
	///
	/// - Parameter profile: The other profile to verify has same ID as `self.profile`.
	private func _assertIdentity(of profile: Profile) throws {
		guard profile.header.id == self.profile.header.id else {
			let errorMessage = "Incorrect implementation: `\(#function)` was called with a Profile which UUID does not match the current one. This should never happen."
			loggerGlobal.critical(.init(stringLiteral: errorMessage))
			assertionFailure(errorMessage)
			throw Error.profileIDMismatch
		}
		// All good
	}

	private func _assertOwnership() throws {
		try _assertOwnership(of: profile)
	}

	private func _assertOwnership(of profile: Profile) throws {
		try Self._assertOwnership(of: profile, against: deviceInfo) {
			emitOwnershipConflict(with: profile)
		}
	}

	private func emitOwnershipConflict(with profile: Profile) {
		emitOwnershipConflict(ownerOfCurrentProfile: profile.header.lastUsedOnDevice)
	}

	private func emitOwnershipConflict(ownerOfCurrentProfile: DeviceInfo) {
		let conflict = OwnershipConflict(
			ownerOfCurrentProfile: ownerOfCurrentProfile,
			thisDevice: deviceInfo
		) { conflictResolutionByUser in
			switch conflictResolutionByUser {
			case .deleteProfileOnThisDevice: try await self.deleteProfile(keepInICloudIfPresent: true)
			case .reclaimProfileOnThisDevice: try await self.claimOwnershipOfProfile()
			}
		}

		ownershipConflictSubject.send(conflict)
	}

	private static func _assertOwnership(
		of profile: Profile,
		against infoAboutThisDevice: DeviceInfo,
		onMismatch: () -> Void
	) throws {
		guard profile.header.lastUsedOnDevice.id == infoAboutThisDevice.id else {
			let errorMessage = "Device ID mismatch, profile might have been used on another device. Last used in header was: \(String(describing: profile.header.lastUsedOnDevice)) and info of this device: \(String(describing: infoAboutThisDevice))"
			loggerGlobal.error(.init(stringLiteral: errorMessage))
			onMismatch()
			throw Error.profileUsedOnAnotherDevice
		}
		// All good
	}
}

// MARK: Private Static
extension ProfileStore {
	private static func _loadSavedElseNewProfile(
		metaDeviceInfo: MetaDeviceInfo
	) -> (deviceInfo: DeviceInfo, profile: Profile, conflictingOwners: ConflictingOwners?) {
		let deviceInfo = metaDeviceInfo.deviceInfo
		do {
			if var existing = try _tryLoadSavedProfile() {
				// Read: https://radixdlt.atlassian.net/l/cp/fmoH9KcN
				let matchingIDs = existing.header.lastUsedOnDevice.id == deviceInfo.id
				if metaDeviceInfo.fromDeprecatedDeviceID, matchingIDs {
					// Same ID => migrate
					existing.header.lastUsedOnDevice = deviceInfo
				}
				return (
					deviceInfo: deviceInfo,
					profile: existing,
					conflictingOwners: matchingIDs ? nil : .init(
						ownerOfCurrentProfile: existing.header.lastUsedOnDevice,
						thisDevice: deviceInfo
					)
				)
			} else {
				return try (
					deviceInfo: metaDeviceInfo.deviceInfo,
					profile: _tryGenerateAndSaveNewProfile(deviceInfo: deviceInfo),
					conflictingOwners: nil
				)
			}
		} catch {
			fatalError("Unable to use app. error: \(error)")
		}
	}

	private static func _tryLoadSavedProfile() throws -> Profile? {
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaultsClient) var userDefaultsClient

		guard
			let profileId = userDefaultsClient.getActiveProfileID(),
			let snapshot = try secureStorageClient.loadProfileSnapshot(profileId)
		else {
			return nil
		}

		return Profile(snapshot: snapshot)
	}

	private static func _tryGenerateAndSaveNewProfile(deviceInfo: DeviceInfo) throws -> Profile {
		let (profile, bdfsMnemonic) = try _newProfileAndBDFSMnemonic(deviceInfo: deviceInfo)
		try _persist(bdfsMnemonic: bdfsMnemonic)
		try _save(profile: profile)
		return profile
	}

	/// Updates `headerList` (Keychain),  `activeProfileID` (UserDefaults) and saves a
	/// snapshot of the profile into Keychain.
	/// - Parameter profile: Profile to save
	private static func _save(profile: Profile) throws {
		try _updateHeaderList(with: profile.header)
		_setActiveProfile(to: profile.header)
		try _persist(profile: profile)
	}

	private static func _newProfileAndBDFSMnemonic(
		deviceInfo creatingDevice: DeviceInfo
	) throws -> (profile: Profile, bdfsMnemonic: PrivateHDFactorSource) {
		@Dependency(\.uuid) var uuid
		@Dependency(\.date) var date
		@Dependency(\.mnemonicClient) var mnemonicClient

		let profileID = uuid()
		let header = ProfileSnapshot.Header(
			creatingDevice: creatingDevice,
			lastUsedOnDevice: creatingDevice,
			id: profileID,
			lastModified: date.now,
			contentHint: .init()
		)

		let mnemonic = try MnemonicWithPassphrase(
			mnemonic: mnemonicClient.generate(
				BIP39.WordCount.twentyFour,
				BIP39.Language.english
			)
		)

		let bdfs = try DeviceFactorSource.babylon(
			mnemonicWithPassphrase: mnemonic,
			model: "iPhone",
			name: "iPhone"
		)

		let bdfsMnemonic = try PrivateHDFactorSource(
			mnemonicWithPassphrase: mnemonic,
			factorSource: bdfs
		)

		let profile = Profile(
			header: header,
			deviceFactorSource: bdfs
		)

		return (profile, bdfsMnemonic)
	}

	/// If `fromDeprecatedDeviceID` is true, a migration might be needed
	// See: https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	private static func _deviceInfo() -> MetaDeviceInfo {
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.uuid) var uuid
		@Dependency(\.date) var date

		func createNew(deviceID: DeviceID? = nil) -> DeviceInfo {
			.init(
				description: "iPhone",
				id: deviceID ?? uuid(),
				date: date.now
			)
		}

		if let existing = try? secureStorageClient.loadDeviceInfo() {
			return MetaDeviceInfo(deviceInfo: existing, fromDeprecatedDeviceID: false)
		}
		let new: DeviceInfo
		let fromDeprecatedDeviceID: Bool

		do {
			if let legacyDeviceID = try? secureStorageClient.deprecatedLoadDeviceID() {
				new = createNew(deviceID: legacyDeviceID)
				fromDeprecatedDeviceID = true
			} else {
				new = createNew()
				fromDeprecatedDeviceID = false
			}
			try secureStorageClient.saveDeviceInfo(new)
			if fromDeprecatedDeviceID {
				// Delete only if `saveDeviceInfo` was successful.
				secureStorageClient.deleteDeprecatedDeviceID()
			}
			return MetaDeviceInfo(deviceInfo: new, fromDeprecatedDeviceID: fromDeprecatedDeviceID)
		} catch {
			loggerGlobal.error("Failed to save new device info: \(error)")
			return MetaDeviceInfo(deviceInfo: new, fromDeprecatedDeviceID: fromDeprecatedDeviceID)
		}
	}

	private static func _updateHeaderList(with header: ProfileSnapshot.Header) throws {
		@Dependency(\.secureStorageClient) var secureStorageClient
		var headers = try secureStorageClient.loadProfileHeaderList()?.rawValue ?? []
		headers[id: header.id] = header
		if let headerList = NonEmpty(rawValue: headers) {
			try secureStorageClient.saveProfileHeaderList(headerList)
		} else {
			struct FailedToUpdateHeaderListWasEmpty: Swift.Error {}
			throw FailedToUpdateHeaderListWasEmpty()
		}
	}

	private static func _setActiveProfile(to header: ProfileSnapshot.Header) {
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		userDefaultsClient.setActiveProfileID(header.id)
	}

	private static func _persist(bdfsMnemonic: PrivateHDFactorSource) throws {
		@Dependency(\.secureStorageClient) var secureStorageClient
		try secureStorageClient.saveMnemonicForFactorSource(bdfsMnemonic)
	}

	private static func _persist(profile: Profile) throws {
		try _persist(profileSnapshot: profile.snapshot())
	}

	private static func _persist(profileSnapshot: ProfileSnapshot) throws {
		@Dependency(\.secureStorageClient) var secureStorageClient
		try secureStorageClient.saveProfileSnapshot(profileSnapshot)
	}
}

// MARK: - MetaDeviceInfo
private struct MetaDeviceInfo: Sendable, Hashable {
	let deviceInfo: DeviceInfo
	let fromDeprecatedDeviceID: Bool
}
