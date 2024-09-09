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
	public static let shared = ProfileStore()

	/// Only mutable since we need to update the description with async, since reading
	/// device model and name is async.
	private var deviceInfo: DeviceInfo

	private let profileSubject: AsyncReplaySubject<Profile> = .init(bufferSize: 1)
	private let profileStateSubject: AsyncReplaySubject<ProfileState> = .init(bufferSize: 1)

	init() {
		let metaDeviceInfo = Self._deviceInfo()
		self.deviceInfo = metaDeviceInfo.deviceInfo

		Task {
			for try await state in await ProfileStateChangeEventPublisher.shared.eventStream() {
				if case let .loaded(profile) = state {
					self.profileSubject.send(profile)
				}

				self.profileStateSubject.send(state)
			}
		}
	}
}

extension ProfileStore {
	func profile() async -> Profile {
		try! await profileSubject.first()
	}

	func profileSequence() async -> AnyAsyncSequence<Profile> {
		profileSubject.eraseToAnyAsyncSequence()
	}

	func profileState() async -> AnyAsyncSequence<ProfileState> {
		await ProfileStateChangeEventPublisher.shared.eventStream().eraseToAnyAsyncSequence()
	}
}

// MARK: Public
extension ProfileStore {
	/// Mutates the in-memory copy of the Profile usung `transform`, and saves a
	/// snapshot of it profile into Keychain (after having updated its header)
	/// - Parameter transform: A mutating transform updating the profile.
	/// - Returns: The result of the transform, often this might be `Void`.
	public func updating<T: Sendable>(
		_ transform: @Sendable (inout Profile) async throws -> T
	) async throws -> T {
		var updated = await profile()
		let result = try await transform(&updated)
		try await SargonOS.shared.setProfile(profile: updated)
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
	public func importProfile(_ profileToImport: Profile, skippedMainBdfs: Bool) async throws {
		try await SargonOS.shared.importWallet(profile: profileToImport, bdfsSkipped: skippedMainBdfs)
	}

	public func deleteProfile() async throws {
		try await SargonOS.shared.deleteWallet()
	}

	public func newProfile() async throws {
		let userDefaults = UserDefaults.Dependency.radix

		try await SargonOS.shared.newWallet()
		let profile = try SargonOS.shared.profile()
		userDefaults.setActiveProfileID(profile.id)
	}

	public func finishOnboarding(
		with accountsRecoveredFromScanningUsingMnemonic: AccountsRecoveredFromScanningUsingMnemonic
	) async throws {
		@Dependency(\.uuid) var uuid
		@Dependency(\.date) var date
		loggerGlobal.notice("Finish onboarding with accounts recovered from scanning using menmonic")
		let deviceInfo = Self._deviceInfo().deviceInfo
		var bdfs = accountsRecoveredFromScanningUsingMnemonic.deviceFactorSource
		bdfs.hint.name = deviceInfo.description
		bdfs.hint.model = deviceInfo.description

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
			authorizedDapps: [],
			resourcePreferences: []
		)

		var lastUsedOnDevice = deviceInfo
		lastUsedOnDevice.date = date()

		let profile = Profile(
			header: Header(
				snapshotVersion: .v100,
				id: uuid(),
				creatingDevice: lastUsedOnDevice,
				lastUsedOnDevice: lastUsedOnDevice,
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
		try await importProfile(profile, skippedMainBdfs: false)
	}

	public func isThisDevice(deviceID: DeviceID) -> Bool {
		deviceInfo.id == deviceID
	}

	public func claimOwnership(of profile: inout Profile) {
		@Dependency(\.date) var date
		profile.header.lastUsedOnDevice = deviceInfo
		profile.header.lastUsedOnDevice.date = date()
		profile.header.lastModified = date()
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

// MARK: Private Static
extension ProfileStore {
	typealias NewProfileTuple = (deviceInfo: DeviceInfo, profile: Profile)

	/// Returns `MetaDeviceInfo` which contains `fromDeprecatedDeviceID` , and if
	/// it is true, a migration of `DeviceID` into `DeviceInfo` might be needed.
	// See: https://radixdlt.atlassian.net/l/cp/fmoH9KcN
	private static func _deviceInfo() -> MetaDeviceInfo {
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.uuid) var uuid
		@Dependency(\.date) var date

		func createNew(deviceID: DeviceID? = nil) -> DeviceInfo {
			// FIXME! Use the HostInfoDriver instead! Or RATHER delete this whole file... SargonOS is gonna do this...
			DeviceInfo(
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
}

// MARK: - MetaDeviceInfo
private struct MetaDeviceInfo: Sendable, Hashable {
	let deviceInfo: DeviceInfo
	let fromDeprecatedDeviceID: Bool
}
