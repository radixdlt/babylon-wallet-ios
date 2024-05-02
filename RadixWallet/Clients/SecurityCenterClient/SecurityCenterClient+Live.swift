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

		Task {
			let profileID = await profileStore.profile.id
			for try await lastBackup in cloudBackupClient.lastBackup(profileID) {
				guard !Task.isCancelled else { return }
				let currentProfileHash = await profileStore.profile.hashValue
				let isUpToDate = lastBackup.profileHash == currentProfileHash
				print("•• Backup changed for \(profileID.uuidString) \(isUpToDate)")
				//			await send(.internal(.setLastBackedUp(isUpToDate ? nil : lastBackup.date)))
			}
		}

		return .init(
			problems: { profileID in
				print("•• subscribe to problems for \(profileID.uuidString)")

				let cloud = userDefaults.lastCloudBackupValues(for: profileID)
//				let hasDoneManualExport = userDefaults.lastManualBackupValues(for: profileID).map { $0. }

				for await dd in AsyncAlgorithms.zip(cloud, manual) {}

//				let dd = merge(cloud, manual)

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
