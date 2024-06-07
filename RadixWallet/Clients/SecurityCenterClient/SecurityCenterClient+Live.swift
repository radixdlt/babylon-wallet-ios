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
			await combineLatest(profileStore.values(), results.prepend(nil))
				.map { profile, backup -> BackupStatus? in
					guard let backup else { return nil }
					let upToDate = backup.saveIdentifier == profile.saveIdentifier
					return .init(
						backupDate: backup.backupDate,
						upToDate: upToDate,
						status: backup.result == .success ? .success : .failed
					)
				}
				.eraseToAnyAsyncSequence()
		}

		let problemsSubject = AsyncCurrentValueSubject<[SecurityProblem]>([])

		@Sendable
		func startMonitoring() async throws {
			let profileValues = await profileStore.values()
			let problematicValues = try await deviceFactorSourceClient.problematicEntities()
			let backupValues = await combineLatest(cloudBackups(), manualBackups()).map { (cloud: $0, manual: $1) }

			for try await (profile, problematic, backups) in combineLatest(profileValues, problematicValues, backupValues) {
				let isCloudProfileSyncEnabled = profile.appPreferences.security.isCloudProfileSyncEnabled

				func hasProblem3() async -> ProblematicAddresses? {
					problematic.unrecoverable.isEmpty ? nil : problematic.unrecoverable
				}

				func hasProblem5() -> Bool {
					if isCloudProfileSyncEnabled, let cloudBackup = backups.cloud {
						cloudBackup.failed
					} else {
						false // FIXME: GK - is this what we want?
					}
				}

				func hasProblem6() -> Bool {
					!isCloudProfileSyncEnabled && backups.manual == nil
				}

				func hasProblem7() -> Bool {
					!isCloudProfileSyncEnabled && backups.manual?.upToDate == false
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
			startMonitoring: startMonitoring,
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
