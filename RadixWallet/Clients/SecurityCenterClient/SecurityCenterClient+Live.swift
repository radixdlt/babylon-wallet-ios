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
				userDefaults.lastBackupValues(for: profileID).map { _ in
					print("•• backup emitted for \(profileID.uuidString)")
				}

				fatalError()
			}
		)
	}
}
