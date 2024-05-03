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

		return .init(
			problems: { profileID in
				let cloudBackups = userDefaults.lastCloudBackupValues(for: profileID).optional
				let cloudBackupsEnabled = await profileStore.appPreferencesValues().map(\.security.isCloudProfileSyncEnabled)
				let manualBackups = userDefaults.lastManualBackupValues(for: profileID).optional

				return combineLatest(cloudBackups, cloudBackupsEnabled, manualBackups).map { cloudBackup, enabled, manualBackup in
					let profile = await profileStore.profile
					var result: [SecurityProblem] = []

					func hasProblem5() -> Bool {
						if let cloudBackup {
							cloudBackup.status != .success
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

					if hasProblem5() { result.append(.problem5) }
					if hasProblem6() { result.append(.problem6) }
					if hasProblem7() { result.append(.problem7) }

					return result
				}
				.eraseToAnyAsyncSequence()
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
