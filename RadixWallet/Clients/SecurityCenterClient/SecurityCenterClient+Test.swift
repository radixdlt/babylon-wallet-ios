import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

extension DependencyValues {
	var securityCenterClient: SecurityCenterClient {
		get { self[SecurityCenterClient.self] }
		set { self[SecurityCenterClient.self] = newValue }
	}
}

// MARK: - SecurityCenterClient + TestDependencyKey
extension SecurityCenterClient: TestDependencyKey {
	static let previewValue: Self = .noop

	static let noop = Self(
		startMonitoring: {},
		problems: { _ in AsyncLazySequence([[]]).eraseToAnyAsyncSequence() },
		lastManualBackup: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		lastCloudBackup: { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)

	static let testValue = Self(
		startMonitoring: unimplemented("\(Self.self).startMonitoring"),
		problems: unimplemented("\(Self.self).problems", placeholder: noop.problems),
		lastManualBackup: unimplemented("\(Self.self).lastManualBackup", placeholder: noop.lastManualBackup),
		lastCloudBackup: unimplemented("\(Self.self).lastCloudBackup", placeholder: noop.lastCloudBackup)
	)
}
