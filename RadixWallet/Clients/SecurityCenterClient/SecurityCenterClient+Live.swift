import AsyncAlgorithms
import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

extension SecurityCenterClient {
	public static let liveValue: Self = .live()

	public func problems() async -> AnyAsyncSequence<[SecurityProblem]> {
		await problems(nil)
	}

	public func isRecoverable() async -> AnyAsyncSequence<Bool> {
		await problems(.configurationBackup)
			.map(\.isEmpty)
			.eraseToAnyAsyncSequence()
	}

	public static func live(
		profileStore: ProfileStore = .shared
	) -> SecurityCenterClient {
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

		@Sendable
		func manualBackups() async -> AnyAsyncSequence<BackupStatus?> {
			let profileID = await profileStore.profile.id
			let backups = userDefaults.lastManualBackupValues(for: profileID)
			return await statusValues(results: backups)
		}

		@Sendable
		func cloudBackups() async -> AnyAsyncSequence<BackupStatus?> {
			let profileID = await profileStore.profile.id
			let backups = userDefaults.lastCloudBackupValues(for: profileID)
			return await statusValues(results: backups)
		}

		@Sendable
		func statusValues(results: AnyAsyncSequence<BackupResult?>) async -> AnyAsyncSequence<BackupStatus?> {
			await combineLatest(profileStore.values(), results.prepend(nil)).map { profile, backup in
				guard let backup else { return nil }
				let upToDate = backup.profileHash == profile.hashValue
				let success = backup.result == .success
				let error: String? = if case let .failure_DEBUG(errorString) = backup.result {
					errorString
				} else {
					nil
				}
				return .init(backupDate: backup.backupDate, upToDate: upToDate, success: success, error: error)
			}
			.eraseToAnyAsyncSequence()
		}

		return .init(
			problems: { type in
				let profiles = await profileStore.values()
				let cloudBackups = await cloudBackups()
				let manualBackups = await manualBackups()

				return combineLatest(profiles, cloudBackups, manualBackups).map { profile, cloudBackup, manualBackup in
					let isCloudProfileSyncEnabled = profile.appPreferences.security.isCloudProfileSyncEnabled

					func hasProblem3() async -> (accounts: Int, personas: Int)? {
						guard let result = try? await deviceFactorSourceClient.unrecoverableEntitiesCount(),
						      result.accounts + result.personas > 0
						else { return nil }
						return result
					}

					func hasProblem5() -> Bool {
						if isCloudProfileSyncEnabled, let cloudBackup {
							!cloudBackup.success
						} else {
							false // FIXME: GK - is this what we want?
						}
					}

					func hasProblem6() -> Bool {
						!isCloudProfileSyncEnabled && manualBackup == nil
					}

					func hasProblem7() -> Bool {
						!isCloudProfileSyncEnabled && manualBackup?.upToDate == false
					}

					func hasProblem9() async -> Bool {
						await (try? deviceFactorSourceClient.isSeedPhraseNeededToRecoverAccounts()) ?? false
					}

					var result: [SecurityProblem] = []

					if type == nil || type == .securityFactors {
						if let (accounts, personas) = await hasProblem3() {
							result.append(.problem3(accounts: accounts, personas: personas))
						}

						if await hasProblem9() { result.append(.problem9) }
					}

					if type == nil || type == .configurationBackup {
						if hasProblem5() { result.append(.problem5) }
						if hasProblem6() { result.append(.problem6) }
						if hasProblem7() { result.append(.problem7) }
					}

					return result
				}
				.eraseToAnyAsyncSequence()
			},
			lastManualBackup: manualBackups,
			lastCloudBackup: cloudBackups
		)
	}
}
