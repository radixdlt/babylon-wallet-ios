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
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

		@Sendable
		func manualBackups() async -> AnyAsyncSequence<BackupStatus> {
			let profileID = await profileStore.profile.id
			let backups = userDefaults.lastManualBackupValues(for: profileID)
			return await combineLatest(profileStore.values(), backups).map { profile, backup in
				let upToDate = backup.profileHash == profile.hashValue
				return .init(backupDate: backup.backupDate, upToDate: upToDate)
			}
			.eraseToAnyAsyncSequence()
		}

		@Sendable
		func cloudBackups() async -> AnyAsyncSequence<BackupStatus> {
			let profileID = await profileStore.profile.id
			let backups = userDefaults.lastCloudBackupValues(for: profileID)
			return await combineLatest(profileStore.values(), backups).map { profile, backup in
				let upToDate = backup.profileHash == profile.hashValue
				return .init(backupDate: backup.backupDate, upToDate: upToDate)
			}
			.eraseToAnyAsyncSequence()
		}

		return .init(
			problems: {
				let profileID = await profileStore.profile.id
				let profiles = await profileStore.values()
				let cloudBackups = await cloudBackups().optional
				let manualBackups = await manualBackups().optional

				return combineLatest(profiles, cloudBackups, manualBackups).map { profile, cloudBackup, manualBackup in
					print("•• SecurityCenterClient problems sequence EMIT")

					let enabled = profile.appPreferences.security.isCloudProfileSyncEnabled
					var result: [SecurityProblem] = []

					func hasProblem5() -> Bool {
						if let cloudBackup {
							cloudBackup.result != .success
						} else {
							false // FIXME: GK - is this what we want?
						}
					}

					func hasProblem6() -> Bool {
						!enabled && manualBackup == nil
					}

					func hasProblem7() -> Bool {
						!enabled && manualBackup != nil && manualBackup?.profileHash != profile.hashValue
					}

					func hasProblem9() async -> Bool {
						await (try? deviceFactorSourceClient.isSeedPhraseNeededToRecoverAccounts()) ?? false
					}

					if hasProblem5() { result.append(.problem5) }
					if hasProblem6() { result.append(.problem6) }
					if hasProblem7() { result.append(.problem7) }
					if await hasProblem9() { result.append(.problem9) }

					return result
				}
				.eraseToAnyAsyncSequence()
			},
			lastManualBackup: manualBackups,
			lastCloudBackup: cloudBackups
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
