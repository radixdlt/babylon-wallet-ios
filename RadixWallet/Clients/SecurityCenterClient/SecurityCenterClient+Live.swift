import AsyncAlgorithms
import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

extension SecurityCenterClient {
	public static let liveValue: Self = .live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> SecurityCenterClient {
		@Dependency(\.cloudBackupClient) var cloudBackupClient
		@Dependency(\.userDefaults) var userDefaults

		return .init(
			problems: { profileID in
				print("•• subscribe to problems for \(profileID.uuidString)")

//				merge(userDefaults.lastCloudBackupValues(for: profileID), userDefaults.lastManualBackupValues(for: profileID))

//					.map { _ in
//					var problems: [SecurityProblem] = []
//
//
//					print("•• backup emitted for \(profileID.uuidString)")
//				}

				fatalError()
			}
		)
	}
}
