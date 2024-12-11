import AsyncAlgorithms
import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

extension SecurityCenterClient {
	static let liveValue: Self = .live()

	func problems() async -> AnyAsyncSequence<[SecurityProblem]> {
		await problems(nil)
	}

	/// Emits `false` if there is at least one Security problem.
	///
	/// Despite `.securityFactors` problems aren't actually related to recoverability status, we are considering them as well so
	/// that user is aware that they still have problems to take care of.
	func isRecoverable() async -> AnyAsyncSequence<Bool> {
		await problems()
			.map(\.isEmpty)
			.eraseToAnyAsyncSequence()
	}

	static func live(
		profileStore: ProfileStore = .shared
	) -> SecurityCenterClient {
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

		@Sendable
		func manualBackups() async -> AnyAsyncSequence<BackupStatus?> {
			let profileID = await profileStore.profile().id
			let backups = userDefaults.lastManualBackupValues(for: profileID)
			return await statusValues(results: backups)
		}

		@Sendable
		func cloudBackups() async -> AnyAsyncSequence<BackupStatus?> {
			let profileID = await profileStore.profile().id
			let backups = userDefaults.lastCloudBackupValues(for: profileID)
				.filter { backup in
					backup?.isFinal ?? true
				}
				.eraseToAnyAsyncSequence()
			return await statusValues(results: backups)
		}

		@Sendable
		func statusValues(results: AnyAsyncSequence<BackupResult?>) async -> AnyAsyncSequence<BackupStatus?> {
			await combineLatest(profileStore.values(), results.prepend(nil))
				.map { profile, backup in
					backup.map { BackupStatus(result: $0, profile: profile) }
				}
				.eraseToAnyAsyncSequence()
		}

		let problemsSubject = AsyncCurrentValueSubject<[SecurityProblem]>([])

		@Sendable
		func startMonitoring() async throws {
			let profileValues = await profileStore.values()
			let entitiesInBadState = try await deviceFactorSourceClient.entitiesInBadState()
			let backupValues = await combineLatest(cloudBackups(), manualBackups()).map { (cloud: $0, manual: $1) }

			for try await (profile, entitiesInBadState, backups) in combineLatest(profileValues, entitiesInBadState, backupValues) {
				let isCloudProfileSyncEnabled = profile.appPreferences.security.isCloudProfileSyncEnabled

				let input = CheckSecurityProblemsInput(
					isCloudProfileSyncEnabled: isCloudProfileSyncEnabled,
					unrecoverableEntities: entitiesInBadState.unrecoverable,
					withoutControlEntities: entitiesInBadState.withoutControl,
					lastCloudBackup: backups.cloud?.asSargon,
					lastManualBackup: backups.manual?.asSargon
				)
				let result = try SargonOS.shared.checkSecurityProblems(input: input)

				problemsSubject.send(result)
			}
		}

		return .init(
			startMonitoring: startMonitoring,
			problems: { kind in
				problemsSubject
					.share()
					.map { $0.filter { kind == nil || $0.kind == kind } }
					.removeDuplicates()
					.eraseToAnyAsyncSequence()
			},
			lastManualBackup: manualBackups,
			lastCloudBackup: cloudBackups
		)
	}
}

private extension AddressesOfEntitiesInBadState {
	var isEmpty: Bool {
		accounts.count + hiddenAccounts.count + personas.count == 0
	}
}

private extension BackupStatus {
	var asSargon: Sargon.BackupResult {
		.init(isCurrent: isCurrent, isFailed: result.failed)
	}
}
