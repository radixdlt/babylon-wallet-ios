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

	/// Emits `false` if there is at least one Security problem.
	///
	/// Despite `.securityFactors` problems aren't actually related to recoverability status, we are considering them as well so
	/// that user is aware that they still have problems to take care of.
	public func isRecoverable() async -> AnyAsyncSequence<Bool> {
		await problems()
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
				let upToDate = backup.saveIdentifier == profile.saveIdentifier
				let success = backup.result == .success
				return .init(backupDate: backup.backupDate, upToDate: upToDate, success: success)
			}
			.eraseToAnyAsyncSequence()
		}

		let problemsSubject = AsyncCurrentValueSubject<[SecurityProblem]>([])

		@Sendable
		func startMonitoringProblems() async throws {
			let profileValues = await profileStore.values()
			let cloudBackupValues = await cloudBackups()
			let manualBackupValues = await manualBackups()
			let problematicValues = try await deviceFactorSourceClient.problematicEntities()

			let first = combineLatest(profileValues, problematicValues)
			let second = combineLatest(cloudBackupValues, manualBackupValues)
			for try await (profileProblematic, backups) in combineLatest(first, second) {
				let isCloudProfileSyncEnabled = profileProblematic.0.appPreferences.security.isCloudProfileSyncEnabled
				let problematic = profileProblematic.1
				let cloudBackup = backups.0
				let manualBackup = backups.1

				func hasProblem3() async -> ProblematicAddresses? {
					problematic.unrecoverable.isEmpty ? nil : problematic.unrecoverable
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

				func hasProblem9() async -> ProblematicAddresses? {
					problematic.mnemonicMissing.isEmpty ? nil : problematic.mnemonicMissing
				}

				var result: [SecurityProblem] = []

				if let addresses = await hasProblem3() {
					result.append(.problem3(addresses: addresses))
				}

				if let addresses = await hasProblem9() {
					result.append(.problem9(addresses: addresses))
				}
				if hasProblem5() { result.append(.problem5) }
				if hasProblem6() { result.append(.problem6) }
				if hasProblem7() { result.append(.problem7) }

				print("M- Sending result: \(result.map(\.number))")

				problemsSubject.send(result)
			}
		}

		return .init(
			startMonitoring: startMonitoringProblems,
			problems: { type in
				problemsSubject
					.share()
					.map { $0.filter { type == nil || $0.type == type } }
					.eraseToAnyAsyncSequence()
			},
			lastManualBackup: manualBackups,
			lastCloudBackup: cloudBackups
		)
	}
}

private extension ProblematicAddresses {
	var isEmpty: Bool {
		accounts.count + hiddenAccounts.count + personas.count == 0
	}
}
