import Sargon

// MARK: - ProfileStore
public final actor ProfileStore {
	public static let shared = ProfileStore()

	private let profileSubject: AsyncReplaySubject<Profile> = .init(bufferSize: 1)
	private let profileStateSubject: AsyncReplaySubject<ProfileState> = .init(bufferSize: 1)

	private init() {
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
		profileStateSubject.share().eraseToAnyAsyncSequence()
	}
}

extension ProfileStore {
	public func newProfile() async throws {
		try await SargonOS.shared.newWallet()
	}

	public func finishOnboarding(
		with accountsRecoveredFromScanningUsingMnemonic: AccountsRecoveredFromScanningUsingMnemonic
	) async throws {
		try await SargonOS.shared.newWalletWithDerivedBdfs(
			hdFactorSource: accountsRecoveredFromScanningUsingMnemonic.factorSource,
			accounts: accountsRecoveredFromScanningUsingMnemonic.accounts.elements
		)
	}

	public func importProfile(_ profileToImport: Profile, skippedMainBdfs: Bool) async throws {
		try await SargonOS.shared.importWallet(profile: profileToImport, bdfsSkipped: skippedMainBdfs)
	}

	public func deleteProfile() async throws {
		try await SargonOS.shared.deleteWallet()
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
		return result
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
}

extension ProfileStore {
	public func isThisDevice(deviceID: DeviceID) async -> Bool {
		guard let hostId = try? await SargonOS.shared.resolveHostId().id else {
			return false
		}

		return hostId == deviceID
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
