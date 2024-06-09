import Sargon

// MARK: - ProfileStore
/// An in-memory holder of the app's `Profile` which syncs changes to *Keychain* and
/// needed state to *UserDefaults* (activeProfileID). If user has iCloud Keychain sync
/// enabled (we can't determine that) and has not disabled `Profile` cloud sync then
/// iOS also syncs updates of `Profile` to iCloud via *Keychain*.
///
/// If a Profile successfully was loaded from Keychain it will be used an `Main` part
/// of app is openened by `Splash`. If no existing Profile was found then a new one
/// alongside a new (babylon) `.device` FactorSource, both persisted into *Keychain*,
/// and user is pushed to `Onboarding`, to create a first account.
///
/// `ProfileStore` is an `actor` so that the in-memory `Profile` is protected against
/// data races, however, it is not a "client" (TCA Dependency), rather it should be used by clients,
/// and only by clients, not by Reducers directly, since it is quite low level.
///
/// This "public interface" (method meant to be used by the clients) is:
///
/// 	var profile: Profile { get }
///		func values() -> AnyAsyncSequence<Profile>
/// 	func unlockedApp() async -> Profile
///	 	func finishedOnboarding() async
///     func finishOnboarding(with _: AccountsRecoveredFromScanningUsingMnemonic) async throws
///	 	func importProfile(_ s: Profile) throws
///	 	func deleteProfile(keepInICloudIfPresent: Bool) throws
/// 	func updating<T>(_ t: (inout Profile) async throws -> T) async throws -> T
///     func claimOwnership(of profile: inout Profile)
///
/// The app is suppose to call `unlockedApp` after user has authenticated from `Splash`, which
/// will emit any Profile ownership conflict if needed, and returns the newly claimed Profile that had
/// ownership conflict if user chose that, else an entirely new Profile is user choses "Clear wallet on other Phone".
///
/// The app is suppose to call `finishedOnboarding` if user just finished onboarding a new wallet, it will
/// async read `device.name` and `device.model` and update the Profile's header's `creatingDevice`
/// and `lastUsedOnDevice` to use these values.
///
/// If a user creates a Profile using Account Recovery Scan, app is supposed to call `finishOnboarding:with`,
/// and create a mainnet `network` **even if AccountsRecoveredFromScanningUsingMnemonic.accounts** is empty,
/// ensuring next time the user starts app, they will not be met with onboarding..., but rather `Home`, with
/// an empty account list.
///
/// And then a lot of sugar/convenience AsyncSequences using `values` but mapping to other
/// values inside of `Profile`, e.g.:
///
/// 	func accountValues() async -> AnyAsyncSequence<Accounts>
///
/// And similar async sequences.
///
public final actor ProfileStore {
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.userDefaults) var userDefaults

	public static let shared = ProfileStore()

	/// Holds an in-memory copy of the Profile, the source of truth is Keychain.
	private let profileSubject: AsyncCurrentValueSubject<Profile>

	/// Only mutable since we need to update the description with async, since reading
	/// device model and name is async.
	private var deviceInfo: DeviceInfo

	/// After user has pass keychain auth prompt in Splash this becomes
	/// `appIsUnlocked`. The idea is that we buffer ownership conflicts until UI
	/// is ready to display it, reason being we dont wanna display the
	/// OverlayClient UI for ownership conflict simultaneously as
	/// unlock app keychain auth prompt.
	private var mode: Mode

	private enum Mode {
		case appIsUnlocked
		case appIsLocked
	}

	init() {
		let metaDeviceInfo = Self._deviceInfo()
		let (deviceInfo, profile) = Self._loadSavedElseNewProfile(metaDeviceInfo: metaDeviceInfo)
		loggerGlobal.info("profile.id: \(profile.id)")
		loggerGlobal.info("device.id: \(deviceInfo.id)")
		self.deviceInfo = deviceInfo
		self.profileSubject = AsyncCurrentValueSubject(profile)
		self.mode = .appIsLocked
	}
}

// MARK: Public
extension ProfileStore {
	/// The current value of Profile. Use `updating` method to update it. Also see `values` for an AsyncSequence of Profile.
	public var profile: Profile {
		profileSubject.value
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
		try updateHeaderOfThenSave(profile: updated)
		return result // in many cases `Void`.
	}

	/// Update Profile, by updating the current network
	/// - Parameter update: A mutating update to perform on the profiles's active network
	public func updatingOnCurrentNetwork(_ update: @Sendable (inout ProfileNetwork) async throws -> Void) async throws {
		try await updating { profile in
			var network = try await network()
			try await update(&network)
			try profile.updateOnNetwork(network)
		}
	}

	/// Change current profile to new importedProfile and saves it, by
	/// updates `headerList` (Keychain),  `activeProfileID` (UserDefaults)
	/// and saves a snapshot of the profile into Keychain.
	///
	/// NB: The profile should be claimed locally before calling this function
	/// - Parameter profile: Imported Profile to use and save.
	public func importProfile(_ profileToImport: Profile) throws {
		// The software design of ProfileStore is to always have a profile at end
		// of `ProfileStore.init`, which happens upon app launch since `ProfileStore`
		// is a GlobalActor (`static let shared = ProfileStore`), this means that
		// a user which does RESTORE from backup will have a new empty Profile in
		// memory `self.profile` in ProfileStore - and in keychain. We call this
		// ephemeral profile and we should delete it after the importing of the
		// profile to import was successful, if it was empty (which it will be).
		let idOfEphemeralProfileToDelete = self.profile.networks.isEmpty ? self.profile.id : nil

		var profileToImport = profileToImport

		// We need to save before calling `updateHeaderOfThenSave`
		try _saveProfileAndEmitUpdate(profileToImport)

		profileToImport.changeCurrentToMainnetIfNeeded()

		try updateHeaderOfThenSave(
			profile: profileToImport
		)

		if let idOfEphemeralProfileToDelete {
			Self.deleteEphemeralProfile(id: idOfEphemeralProfileToDelete)
		}
	}

	private static func deleteEphemeralProfile(id: ProfileID) {
		@Dependency(\.secureStorageClient) var secureStorageClient
		do {
			try secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs(
				profileID: id,
				keepInICloudIfPresent: false
			)
		} catch {
			// Not important enought to fail
			logAssertionFailure("Failed to delete empty ephemeral profile ID, error: \(error)")
		}
	}

	public func deleteProfile(
		keepInICloudIfPresent: Bool
	) throws {
		try _deleteProfile(
			keepInICloudIfPresent: keepInICloudIfPresent,
			assertOwnership: true
		)
	}

	public func finishedOnboarding() async {
		await updateDeviceInfo()
	}

	public func finishOnboarding(
		with accountsRecoveredFromScanningUsingMnemonic: AccountsRecoveredFromScanningUsingMnemonic
	) async throws {
		@Dependency(\.uuid) var uuid
		loggerGlobal.notice("Finish onboarding with accounts recovered from scanning using menmonic")
		let (creatingDevice, model, name) = await updateDeviceInfo()
		var bdfs = accountsRecoveredFromScanningUsingMnemonic.deviceFactorSource
		bdfs.hint.name = name
		bdfs.hint.model = .init(model)

		let accounts = accountsRecoveredFromScanningUsingMnemonic.accounts

		// It is important that we always create the mainnet `ProfileNetwork` and
		// add it, even if `accounts` is empty, since during App launch we check
		// `profile.networks.isEmpty` to determine if we should onboard the user or not,
		// thus, this ensures that we do not onboard a user who has created Profile
		// via Account Recovery Scan with 0 accounts if said user force quits app before
		// she creates her first account.
		let network = ProfileNetwork(
			id: .mainnet,
			accounts: accounts.elements, // FIXME: Declare init in (Swift)Sargon accepting `Accounts` (IdentifiedArrayOf<Account>) ?
			personas: [],
			authorizedDapps: []
		)

		let profile = Profile(
			header: Header(
				snapshotVersion: .v100,
				id: uuid(),
				creatingDevice: creatingDevice,
				lastUsedOnDevice: creatingDevice,
				lastModified: bdfs.addedOn,
				contentHint: .init(
					numberOfAccountsOnAllNetworksInTotal: UInt16(
						accounts.count
					),
					numberOfPersonasOnAllNetworksInTotal: 0,
					numberOfNetworks: 1
				)
			),
			factorSources: [bdfs.asGeneral],
			appPreferences: .default,
			networks: [network]
		)

		// We can "piggyback" on importProfile! Same logic applies!
		try importProfile(profile)
	}

	public func isThisDevice(deviceID: DeviceID) -> Bool {
		deviceID == deviceInfo.id
	}

	public func unlockedApp() async -> Profile {
		loggerGlobal.notice("Unlocking app")
		self.mode = .appIsUnlocked
		return profile
	}
}

extension DeviceInfo {
	public static func deviceDescription(
		name: String,
		model: String
	) -> String {
		"\(model) (\(name))"
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
		profileSubject.compactMap(transform)
			.share() // Multicast
			.removeDuplicates()
			.eraseToAnyAsyncSequence()
	}
}

// MARK: Private
extension ProfileStore {
	@discardableResult
	private func updateDeviceInfo() async -> (info: DeviceInfo, model: String, name: String) {
		@Dependency(\.device) var device
		let model = await device.model
		let name = await device.name
		let deviceDescription = DeviceInfo.deviceDescription(
			name: name,
			model: model
		)
		deviceInfo.description = deviceDescription
		let lastUsedOnDevice = deviceInfo
		try? secureStorageClient.saveDeviceInfo(lastUsedOnDevice)
		try? await updating {
			$0.header.lastUsedOnDevice = lastUsedOnDevice
			$0.header.creatingDevice.description = deviceDescription
		}
		return (info: lastUsedOnDevice, model: model, name: name)
	}

	private func _deleteProfile(
		keepInICloudIfPresent: Bool,
		assertOwnership: Bool = true
	) throws {
		if assertOwnership {
			// Assert that this device is allowed to make changes on Profile
			try _assertOwnership()
		}

		do {
			userDefaults.removeActiveProfileID()
			try secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs(profile.header.id, keepInICloudIfPresent)
		} catch {
			logAssertionFailure("Error, failed to delete profile or factor source, failure: \(String(describing: error))")
		}

		let profile = try! Self._tryGenerateAndSaveNewProfile(deviceInfo: deviceInfo)
		self.profileSubject.send(profile)
	}

	/// Asserts identity and ownership of a profile, then updates its header, saves it and emits an update.
	/// - Parameter updated: Profile to save (after updating its header).
	private func updateHeaderOfThenSave(
		profile toSave: Profile
	) throws {
		guard toSave != profile else {
			// prevent duplicates
			loggerGlobal.info("Same profile, nothing to update.")
			return
		}

		try _assertIdentity(of: toSave)
		try _assertOwnership()

		var toSave = toSave
		try _updateHeader(of: &toSave)
		try _saveProfileAndEmitUpdate(toSave)
	}

	private var appIsUnlocked: Bool {
		switch mode {
		case .appIsUnlocked: true
		case .appIsLocked: false
		}
	}
}

// MARK: Helpers
extension ProfileStore {
	/// Updates the `lastUsedOnDevice` to use this device, on `profile`
	/// - Parameter profile: Profile to update `lastUsedOnDevice` of
	public func claimOwnership(of profile: inout Profile) {
		@Dependency(\.date) var date
		profile.header.lastUsedOnDevice = deviceInfo
		profile.header.lastUsedOnDevice.date = date()
	}

	/// Updates the header of a Profile, lastModified date, contentHint etc.
	/// - Parameter profile: Profile with a header to update
	private func _updateHeader(of profile: inout Profile) throws {
		@Dependency(\.date) var date
		let networks = profile.networks

		profile.header.lastModified = date.now
		profile.header.contentHint.numberOfNetworks = UInt16(networks.count)
		profile.header.contentHint.numberOfAccountsOnAllNetworksInTotal = UInt16(networks.map { $0.getAccounts().count }.reduce(0, +))
		profile.header.contentHint.numberOfPersonasOnAllNetworksInTotal = UInt16(networks.map { $0.getPersonas().count }.reduce(0, +))
	}

	/// Updates the in-memory copy of profile in ProfileStores and saves it, by
	/// updates `headerList` (Keychain),  `activeProfileID` (UserDefaults)
	/// and saves a snapshot of the profile into Keychain.
	/// - Parameter profile: Profile to save
	private func _saveProfileAndEmitUpdate(_ profile: Profile) throws {
		try Self._save(profile: profile)
		profileSubject.send(profile)
	}

	/// Asserts that the **identity** of `profile` matches that of `self.profile`, which
	/// is not using Equality but rather a UUID check.
	///
	/// This does NOT check ownership, for that see: `_assertOwnership:of`
	///
	/// - Parameter profile: The other profile to verify has same ID as `self.profile`.
	private func _assertIdentity(of profile: Profile) throws {
		guard profile.header.id == self.profile.header.id else {
			logAssertionFailure("Incorrect implementation: `\(#function)` was called with a Profile which UUID does not match the current one. This should never happen.", severity: .critical)
			throw Error.profileIDMismatch
		}
		// All good
	}

	private func _assertOwnership() throws {
		loggerGlobal.debug("asserting ownership")

		// We don't use in memory version of profile header, but rather read from keychain, this protects
		// from corner case scenario where user is running app on iPhone `A` with Profile `P` then edit the
		// very same profile `P` on iPhone `B` and then going back to iPhone `A` still running and trying
		// to edit Profile `P` again. If we do not read profile header from keychain - which might have
		// synced over iCloud - then iPhone `A` will never have detected that iPhone `B` made changes, so
		// by reading from keychain we might pick up that change.
		let header = (try? secureStorageClient.loadProfileSnapshot(profile.id)?.header) ?? profile.header

		guard deviceInfo.id == header.lastUsedOnDevice.id else {
			loggerGlobal.error("Device ID mismatch, profile might have been used on another device. Last used in header was: \(String(describing: header.lastUsedOnDevice)) and info of this device: \(String(describing: deviceInfo))")
			throw Error.profileUsedOnAnotherDevice
		}
		// All good
	}
}

// MARK: Private Static
extension ProfileStore {
	typealias NewProfileTuple = (deviceInfo: DeviceInfo, profile: Profile)

	private static func _loadSavedElseNewProfile(
		metaDeviceInfo: MetaDeviceInfo
	) -> NewProfileTuple {
		@Dependency(\.secureStorageClient) var secureStorageClient
		let deviceInfo = metaDeviceInfo.deviceInfo

		func newProfile() throws -> NewProfileTuple {
			try (
				deviceInfo: metaDeviceInfo.deviceInfo,
				profile: _tryGenerateAndSaveNewProfile(deviceInfo: deviceInfo)
			)
		}

		do {
			if var existing = try _tryLoadSavedProfile() {
				if
					case let bdfs = existing.factorSources.asIdentified().babylonDevice,
					!secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(bdfs.id),
					existing.networks.isEmpty
				{
					// Unlikely corner case, but possible. The Profile does not contain any accounts and
					// the BDFS mnemonic is missing => treat this scenario as if there is no Profile ->
					// let user start fresh. It is possible for users to end up in this corner case scenario
					// if the do this:
					// 1. Start wallet without any Profile => a new Profile and BDFS is saved into keychain (and BDFS mnemonic)
					// 2. Before they create the first account, they delete the passcode from their device and re-enabling it, this
					// 		will delete the mnemonic from keychain, but not the Profile.
					// 3. Start wallet again, and they are met with onboarding screen to create their first acocunt into the empty
					// 		Profile created in step 1. HOWEVER, they user is now stuck in a bad state. The account creation will
					// 		try to use a missing mnemonic which silently fails and user gets back to the screen where they are asked
					//		to name the account.
					//
					//	The solution is simple, this Profile has no value! It has no accounts! So we just toss it and generate a new
					//	(Profile, BDFS) pair, with the mnemonic of this new BDFS intact in keychain.
					Self.deleteEphemeralProfile(id: existing.header.id)
					return try newProfile()
				}

				// Read: https://radixdlt.atlassian.net/l/cp/fmoH9KcN
				let matchingIDs = existing.header.lastUsedOnDevice.id == deviceInfo.id
				if metaDeviceInfo.fromDeprecatedDeviceID, matchingIDs {
					// Same ID => migrate
					existing.header.lastUsedOnDevice = deviceInfo
				}
				return (
					deviceInfo: deviceInfo,
					profile: existing
				)
			} else {
				return try newProfile()
			}
		} catch {
			fatalError("Unable to use app. error: \(error)")
		}
	}

	private static func _tryLoadSavedProfile() throws -> Profile? {
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaults) var userDefaults

		guard
			let profileId = userDefaults.getActiveProfileID(),
			let profile = try secureStorageClient.loadProfile(profileId)
		else {
			return nil
		}

		if let profileSnapshotData = try? secureStorageClient.loadProfileSnapshotData(profileId) {
			let containsLegacyP2PLinks = Profile.checkIfProfileJsonContainsLegacyP2PLinks(contents: profileSnapshotData)
			userDefaults.setShowRelinkConnectorsAfterUpdate(containsLegacyP2PLinks)

			/// If a profile contains legacy P2P links, we replace it with a newly decoded profile.
			/// Since the new profile does not store P2P links, this operation will remove the legacy P2P links.
			if containsLegacyP2PLinks {
				try? _save(profile: profile)
			}
		}

		return profile
	}

	private static func _tryGenerateAndSaveNewProfile(
		deviceInfo: DeviceInfo
	) throws -> Profile {
		let (profile, bdfsMnemonic) = _newProfileAndBDFSMnemonic(deviceInfo: deviceInfo)
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
	) -> (
		profile: Profile,
		bdfsMnemonic: PrivateHierarchicalDeterministicFactorSource
	) {
		@Dependency(\.uuid) var uuid
		@Dependency(\.date) var date
		@Dependency(\.mnemonicClient) var mnemonicClient

		let profileID = uuid()
		let header = Profile.Header(
			snapshotVersion: .v100,
			id: profileID,
			creatingDevice: creatingDevice,
			lastUsedOnDevice: creatingDevice,
			lastModified: date.now,
			contentHint: .init(
				numberOfAccountsOnAllNetworksInTotal: 0,
				numberOfPersonasOnAllNetworksInTotal: 0,
				numberOfNetworks: 0
			)
		)

		let mnemonic = MnemonicWithPassphrase(
			mnemonic: mnemonicClient.generate(
				BIP39WordCount.twentyFour,
				BIP39Language.english
			),
			passphrase: ""
		)

		let bdfs = DeviceFactorSource.babylon(
			mnemonicWithPassphrase: mnemonic,
			isMain: true
		)

		let bdfsMnemonic = PrivateHierarchicalDeterministicFactorSource(
			mnemonicWithPassphrase: mnemonic,
			factorSource: bdfs
		)

		let profile = Profile(
			header: header,
			deviceFactorSource: bdfs
		)

		return (profile, bdfsMnemonic)
	}

	/// Returns `MetaDeviceInfo` which contains `fromDeprecatedDeviceID` , and if
	/// it is true, a migration of `DeviceID` into `DeviceInfo` might be needed.
	// See: https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	private static func _deviceInfo() -> MetaDeviceInfo {
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.uuid) var uuid
		@Dependency(\.date) var date

		func createNew(deviceID: DeviceID? = nil) -> DeviceInfo {
			.init(
				id: deviceID ?? uuid(),
				date: date.now,
				description: "iPhone"
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

	private static func _updateHeaderList(with header: Profile.Header) throws {
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

	private static func _setActiveProfile(to header: Profile.Header) {
		@Dependency(\.userDefaults) var userDefaults
		userDefaults.setActiveProfileID(header.id)
	}

	/// **B**abylon **D**evice **F**actor **S**ource
	private static func _persist(bdfsMnemonic: PrivateHierarchicalDeterministicFactorSource) throws {
		@Dependency(\.secureStorageClient) var secureStorageClient
		try secureStorageClient.saveMnemonicForFactorSource(bdfsMnemonic)
	}

	private static func _persist(profile: Profile) throws {
		@Dependency(\.secureStorageClient) var secureStorageClient
		try secureStorageClient.saveProfileSnapshot(profile)
	}
}

// MARK: - MetaDeviceInfo
private struct MetaDeviceInfo: Sendable, Hashable {
	let deviceInfo: DeviceInfo
	let fromDeprecatedDeviceID: Bool
}
