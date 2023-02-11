import Cryptography
import Prelude

private func key(from factorSourceReference: FactorSourceReference) -> String {
	factorSourceReference.id
}

private func key(from factorInstanceID: FactorInstanceID) -> String {
	factorInstanceID.id
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
		mnemonic: Mnemonic,
		protection: Protection? = nil,
		reference factorSourceReference: FactorSourceReference
	) async throws {
		try await updateFactorSource(
			data: mnemonic.entropy().data,
			reference: factorSourceReference,
			protection: protection
		)
	}

	public func updateFactorSource(
		data: Data,
		reference factorSourceReference: FactorSourceReference,
		protection: Protection? = nil
	) async throws {
		try await updateDataForKey(
			data,
			key(from: factorSourceReference),
			protection,
			nil
		)
	}

	public func updateFactorInstance(
		privateKey: Curve25519.Signing.PrivateKey,
		factorInstanceID: FactorInstanceID,
		protection: Protection? = nil
	) async throws {
		try await updateDataForKey(
			privateKey.rawRepresentation,
			key(from: factorInstanceID),
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

	public func loadFactorSourceMnemonic(
		reference factorSourceReference: FactorSourceReference,
		authenticationPrompt: AuthenticationPrompt
	) async throws -> Mnemonic? {
		guard let data = try await loadFactorSourceData(
			reference: factorSourceReference,
			authenticationPrompt: authenticationPrompt
		) else { return nil }
		return try Mnemonic(entropy: .init(data: data))
	}

	public func loadFactorSourceData(
		reference factorSourceReference: FactorSourceReference,
		authenticationPrompt: AuthenticationPrompt
	) async throws -> Data? {
		try await dataForKey(key(from: factorSourceReference), authenticationPrompt)
	}

	public func loadFactorInstancePrivateKey(
		factorInstanceID: FactorInstanceID,
		authenticationPrompt: AuthenticationPrompt
	) async throws -> Curve25519.Signing.PrivateKey? {
		guard let data = try await dataForKey(key(from: factorInstanceID), authenticationPrompt) else { return nil }
		return try .init(rawRepresentation: data)
	}
}

// MARK: Remove
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
		for factorSource in profile.factorSources.anyFactorSources {
			try await self.removeDataForFactorSource(reference: factorSource.reference)
		}

		try await removeProfileSnapshot()
	}

	public func removeProfileSnapshot() async throws {
		try await removeDataForKey(profileSnapshotKeychainKey)
	}

	public func removeDataForFactorSource(
		reference factorSourceReference: FactorSourceReference
	) async throws {
		try await removeDataForKey(key(from: factorSourceReference))
	}

	public func removeDataForFactorInstance(
		id factorInstanceID: FactorInstanceID
	) async throws {
		try await removeDataForKey(key(from: factorInstanceID))
	}
}
