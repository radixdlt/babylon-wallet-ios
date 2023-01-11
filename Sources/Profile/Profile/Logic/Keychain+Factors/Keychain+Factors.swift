import CryptoKit
import Foundation
import KeychainClient
import Mnemonic

private func key(from factorSourceReference: FactorSourceReference) -> String {
	factorSourceReference.id
}

private func key(from factorInstanceID: FactorInstanceID) -> String {
	factorInstanceID.id
}

private let profileSnapshotKeychainKey = "profileSnapshotKeychainKey"

// MARK: Save
public extension KeychainClient {
	func updateProfile(
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

	func updateProfileSnapshot(
		profileSnapshot: ProfileSnapshot,
		protection: Protection? = .defaultForProfile,
		authentcationPrompt: AuthenticationPrompt? = nil,
		jsonEncoder: JSONEncoder = .iso8601
	) async throws {
		let data = try jsonEncoder.encode(profileSnapshot)
		try await updateDataForKey(data, profileSnapshotKeychainKey, protection, authentcationPrompt)
	}

	func updateFactorSource(
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

	func updateFactorSource(
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

	func updateFactorInstance(
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
public extension KeychainClient {
	func loadProfile(
		authenticationPrompt: AuthenticationPrompt,
		jsonDecoder: JSONDecoder = .iso8601
	) async throws -> Profile? {
		guard let snapshot = try await loadProfileSnapshot(
			jsonDecoder: jsonDecoder,
			authenticationPrompt: authenticationPrompt
		) else { return nil }
		return try Profile(snapshot: snapshot)
	}

	func loadProfileSnapshotJSONData(
		authenticationPrompt: AuthenticationPrompt
	) async throws -> Data? {
		try await dataForKey(profileSnapshotKeychainKey, authenticationPrompt)
	}

	func loadProfileSnapshot(
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

	func loadFactorSourceMnemonic(
		reference factorSourceReference: FactorSourceReference,
		authenticationPrompt: AuthenticationPrompt
	) async throws -> Mnemonic? {
		guard let data = try await loadFactorSourceData(
			reference: factorSourceReference,
			authenticationPrompt: authenticationPrompt
		) else { return nil }
		return try Mnemonic(entropy: .init(data: data))
	}

	func loadFactorSourceData(
		reference factorSourceReference: FactorSourceReference,
		authenticationPrompt: AuthenticationPrompt
	) async throws -> Data? {
		try await dataForKey(key(from: factorSourceReference), authenticationPrompt)
	}

	func loadFactorInstancePrivateKey(
		factorInstanceID: FactorInstanceID,
		authenticationPrompt: AuthenticationPrompt
	) async throws -> Curve25519.Signing.PrivateKey? {
		guard let data = try await dataForKey(key(from: factorInstanceID), authenticationPrompt) else { return nil }
		return try .init(rawRepresentation: data)
	}
}

// MARK: Remove
public extension KeychainClient {
	func removeAllFactorSourcesAndProfileSnapshot(
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

	func removeProfileSnapshot() async throws {
		try await removeDataForKey(profileSnapshotKeychainKey)
	}

	func removeDataForFactorSource(
		reference factorSourceReference: FactorSourceReference
	) async throws {
		try await removeDataForKey(key(from: factorSourceReference))
	}

	func removeDataForFactorInstance(
		id factorInstanceID: FactorInstanceID
	) async throws {
		try await removeDataForKey(key(from: factorInstanceID))
	}
}

public extension JSONDecoder {
	static var iso8601: JSONDecoder {
		let jsonDecoder = JSONDecoder()
		jsonDecoder.dateDecodingStrategy = .iso8601
		return jsonDecoder
	}
}

public extension JSONEncoder {
	static var iso8601: JSONEncoder {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
		return encoder
	}
}
