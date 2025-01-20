import Sargon

// MARK: - ProfileStore
// Until we fully migrate to have everything Profile in SargonOS, this will be kept in place.
// The next steps for migration are outlined in https://radixdlt.atlassian.net/browse/ABW-3590.
final actor ProfileStore {
	static let shared = ProfileStore()

	private let profileSubject: AsyncCurrentValueSubject<Profile?> = .init(nil)
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
	func profile() -> Profile {
		guard let profile = profileSubject.value else {
			fatalError("Programmer error - tried to access profile when it was not loaded yet.")
		}
		return profile
	}

	func profileStateSequence() async -> AnyAsyncSequence<ProfileState> {
		profileStateSubject.share().eraseToAnyAsyncSequence()
	}
}

extension ProfileStore {
	func createNewProfile() async throws {
		let shouldPrederiveInstances: Bool
		#if DEBUG
		shouldPrederiveInstances = true
		#else
		shouldPrederiveInstances = false
		#endif
		return try await SargonOS.shared.newWallet(shouldPrederiveInstances: shouldPrederiveInstances)
	}

	func finishOnboarding(
		with accountsRecoveredFromScanningUsingMnemonic: AccountsRecoveredFromScanningUsingMnemonic
	) async throws {
		try await SargonOS.shared.newWalletWithDerivedBdfs(
			hdFactorSource: accountsRecoveredFromScanningUsingMnemonic.factorSource,
			accounts: accountsRecoveredFromScanningUsingMnemonic.accounts.elements
		)
	}

	func importProfile(_ profileToImport: Profile, skippedMainBdfs: Bool) async throws {
		var profileToImport = profileToImport
		profileToImport.changeCurrentToMainnetIfNeeded()
		try await SargonOS.shared.importWallet(profile: profileToImport, bdfsSkipped: skippedMainBdfs)
	}

	func deleteProfile() async throws {
		try await SargonOS.shared.deleteWallet()
	}
}

// MARK: Public
extension ProfileStore {
	/// Mutates the in-memory copy of the Profile usung `transform`, and saves a
	/// snapshot of it profile into Keychain (after having updated its header)
	/// - Parameter transform: A mutating transform updating the profile.
	/// - Returns: The result of the transform, often this might be `Void`.
	func updating<T: Sendable>(
		_ transform: @Sendable (inout Profile) async throws -> T
	) async throws -> T {
		var updated = profile()
		let result = try await transform(&updated)
		try await SargonOS.shared.setProfile(profile: updated)
		return result
	}

	/// Update Profile, by updating the current network
	/// - Parameter update: A mutating update to perform on the profiles's active network
	func updatingOnCurrentNetwork(_ update: @Sendable (inout ProfileNetwork) async throws -> Void) async throws {
		try await updating { profile in
			var network = try await network()
			try await update(&network)
			try profile.updateOnNetwork(network)
		}
	}
}

// MARK: "Private"
extension ProfileStore {
	func _lens<Property>(
		_ transform: @escaping @Sendable (Profile) -> Property?
	) -> AnyAsyncSequence<Property> where Property: Sendable & Equatable {
		profileSubject
			.compactMap { $0.flatMap(transform) }
			.share() // Multicast
			.removeDuplicates()
			.eraseToAnyAsyncSequence()
	}
}
