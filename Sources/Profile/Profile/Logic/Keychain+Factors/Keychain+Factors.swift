import Cryptography
import Prelude

private func key(factorSourceID: FactorSource.ID) -> String {
	factorSourceID.hexCodable.hex()
}

private let profileSnapshotKeychainKey = "profileSnapshotKeychainKey"

// MARK: Save
extension KeychainClient {
	public func updateProfile(
		profile: Profile,
		protection: Protection? = .defaultForProfile,
		authentcationPrompt: AuthenticationPrompt? = nil,
		jsonEncoder: JSONEncoder = .iso8601
	) async throws {
		let snapshot = profile.snaphot()
		try await updateProfileSnapshot(
			profileSnapshot: snapshot,
			protection: protection,
			authentcationPrompt: authentcationPrompt,
			jsonEncoder: jsonEncoder
		)
	}

	public func updateProfileSnapshot(
		profileSnapshot: ProfileSnapshot,
		protection: Protection? = .defaultForProfile,
		authentcationPrompt: AuthenticationPrompt? = nil,
		jsonEncoder: JSONEncoder = .iso8601
	) async throws {
		let data = try jsonEncoder.encode(profileSnapshot)
		try await updateDataForKey(data, profileSnapshotKeychainKey, protection, authentcationPrompt)
	}

	public func updateFactorSource(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		protection: Protection? = nil,
		factorSourceID: FactorSource.ID
	) async throws {
		@Dependency(\.jsonEncoder) var jsonEncoder
		let jsonData = try jsonEncoder().encode(mnemonicWithPassphrase)
		try await updateFactorSource(
			data: jsonData,
			factorSourceID: factorSourceID,
			protection: protection
		)
	}

	public func updateFactorSource(
		data: Data,
		factorSourceID: FactorSource.ID,
		protection: Protection? = nil
	) async throws {
		try await updateDataForKey(
			data,
			key(factorSourceID: factorSourceID),
			protection,
			nil
		)
	}
}

// MARK: Load
extension KeychainClient {
	public func loadProfile(
		authenticationPrompt: AuthenticationPrompt,
		jsonDecoder: JSONDecoder = .iso8601
	) async throws -> Profile? {
		guard let snapshot = try await loadProfileSnapshot(
			jsonDecoder: jsonDecoder,
			authenticationPrompt: authenticationPrompt
		) else { return nil }
		return try Profile(snapshot: snapshot)
	}

	public func loadProfileSnapshotJSONData(
		authenticationPrompt: AuthenticationPrompt
	) async throws -> Data? {
		try await dataForKey(profileSnapshotKeychainKey, authenticationPrompt)
	}

	public func loadProfileSnapshot(
		jsonDecoder: JSONDecoder = .iso8601,
		authenticationPrompt: AuthenticationPrompt
	) async throws -> ProfileSnapshot? {
		guard let profileSnapshotData = try await loadProfileSnapshotJSONData(
			authenticationPrompt: authenticationPrompt
		) else {
			return nil
		}
		return try jsonDecoder.decode(ProfileSnapshot.self, from: profileSnapshotData)
	}

	public func loadFactorSourceMnemonicWithPassphrase(
		factorSourceID: FactorSource.ID,
		authenticationPrompt: AuthenticationPrompt
	) async throws -> MnemonicWithPassphrase? {
		@Dependency(\.jsonDecoder) var jsonDecoder
		guard let jsonData = try await loadFactorSourceData(
			factorSourceID: factorSourceID,
			authenticationPrompt: authenticationPrompt
		) else { return nil }
		return try jsonDecoder().decode(MnemonicWithPassphrase.self, from: jsonData)
	}

	public func loadFactorSourceData(
		factorSourceID: FactorSource.ID,
		authenticationPrompt: AuthenticationPrompt
	) async throws -> Data? {
		try await dataForKey(key(factorSourceID: factorSourceID), authenticationPrompt)
	}
}

//// MARK: Remove
extension KeychainClient {
	public func removeAllFactorSourcesAndProfileSnapshot(
		authenticationPrompt: AuthenticationPrompt,
		jsonDecoder: JSONDecoder = .iso8601
	) async throws {
		guard let profile = try await loadProfile(
			authenticationPrompt: authenticationPrompt,
			jsonDecoder: jsonDecoder
		) else {
			return
		}
		for factorSource in profile.factorSources {
			try await self.removeDataForFactorSource(id: factorSource.id)
		}

		try await removeProfileSnapshot()
	}

	public func removeProfileSnapshot() async throws {
		try await removeDataForKey(profileSnapshotKeychainKey)
	}

	public func removeDataForFactorSource(
		id factorSourceID: FactorSource.ID
	) async throws {
		try await removeDataForKey(key(factorSourceID: factorSourceID))
	}
}
