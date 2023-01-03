import Dependencies
import Foundation
import JSON
import KeychainClient
import Profile

public extension ProfileLoader {
	typealias Value = ProfileLoader
	static let liveValue: Self = {
		@Dependency(\.keychainClient) var keychainClient
		@Dependency(\.jsonDecoder) var jsonDecoder
		return Self(
			loadProfile: { @Sendable in
				guard
					let profileSnapshotData = try? await keychainClient
					.loadProfileSnapshotJSONData(
						// This should not be be shown due to settings of profile snapshot
						// item when it was originally stored.
						authenticationPrompt: "Load accounts"
					)
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
					return .failure(.decodingFailure(
						json: profileSnapshotData,
						.unknown(.init(
							error: NoProfileSnapshotVersionFoundInJSONData()
						))
					))
				}

				do {
					try ProfileSnapshot.validateCompatability(version: decodedVersion)
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
						.known(
							.init(decodingError: decodingError)
						)
					)
					)
				} catch {
					return .failure(.decodingFailure(
						json: profileSnapshotData,
						.unknown(.init(error: error))
					))
				}

				do {
					let profile = try Profile(snapshot: profileSnapshot)
					return .success(profile)
				} catch {
					return .failure(.failedToCreateProfileFromSnapshot(
						.init(
							version: profileSnapshot.version,
							error: error
						))
					)
				}
			}
		)
	}()
}

// MARK: - NoProfileSnapshotVersionFoundInJSONData
struct NoProfileSnapshotVersionFoundInJSONData: Swift.Error, LocalizedError {
	var errorDescription: String? {
		"\(Self.self)"
	}
}
