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

		/*
		 5: last cloud backup failed
		 6: cloud backups are turned off + never manually backed up
		 7: cloud backups are turned off + has done manual but not latest
		 */

		return .init(
			problems: { profileID in
				print("•• subscribe to problems for \(profileID.uuidString)")

				let cloudBackups = userDefaults.lastCloudBackupValues(for: profileID).optional
				let manualBackups = userDefaults.lastManualBackupValues(for: profileID).optional

				return AsyncAlgorithms.combineLatest(cloudBackups, manualBackups).map { cloudBackup, manualBackup in

					print("•• cloud \(cloudBackup), manual \(manualBackup)")

					let result = Bool.random() ? [SecurityProblem.problem5] : []
					print("•• PROBLEMS EMIT cloud \(cloudBackup) \(result)")
					return result
				}
				.eraseToAnyAsyncSequence()

//				return cloudBackups.map { cloudBackup in
//					let result = Bool.random() ? [SecurityProblem.problem5] : []
//					print("•• PROBLEMS EMIT cloud \(cloudBackup) \(result)")
//					return result
//				}
//				.eraseToAnyAsyncSequence()
			}
		)
	}
}

extension AsyncSequence where Self: Sendable, Element: Sendable {
	/// A sequence of optional Elements, starting with `nil`. Useful together with `combineLatest`.
	var optional: AnyAsyncSequence<Element?> {
		map { $0 as Element? }
			.prepend(nil)
			.eraseToAnyAsyncSequence()
	}
}
