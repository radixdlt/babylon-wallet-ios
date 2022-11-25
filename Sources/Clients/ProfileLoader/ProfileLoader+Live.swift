import Dependencies
import Foundation
import JSON
import KeychainClientDependency
import Profile

public extension ProfileLoader {
	typealias Value = ProfileLoader
	static let liveValue: Self = {
		@Dependency(\.keychainClient) var keychainClient
		@Dependency(\.jsonDecoder) var jsonDecoder
		return Self(
			loadProfile: { @Sendable in
				guard let profileSnapshotData = try? await keychainClient.loadProfileSnapshotJSONData() else {
					return .noProfile
				}
				do {
					let decodedVersion = try ProfileSnapshot.Version.fromJSON(
						data: profileSnapshotData,
						jsonDecoder: jsonDecoder()
					)

					do {
						try ProfileSnapshot.validateCompatability(version: decodedVersion)

						do {
							let profileSnapshot = try jsonDecoder().decode(ProfileSnapshot.self, from: profileSnapshotData)
							do {
								let profile = try Profile(snapshot: profileSnapshot)
								return .compatibleProfile(profile)
							} catch {
								return .failedToCreateProfileFromSnapshot(.init(version: profileSnapshot.version, error: error))
							}
						} catch let decodingError as Swift.DecodingError {
							return .decodingFailure(json: profileSnapshotData, .known(.init(decodingError: decodingError)))
						} catch {
							return .decodingFailure(json: profileSnapshotData, .unknown(.init(error: error)))
						}
					} catch {
						// Incompatible Versions
						return .profileVersionOutdated(json: profileSnapshotData, version: decodedVersion)
					}
				} catch {
					return .decodingFailure(json: profileSnapshotData, .unknown(.init(error: NoProfileSnapshotVersionFoundInJSONData())))
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
