import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

extension DependencyValues {
	public var securityCenterClient: SecurityCenterClient {
		get { self[SecurityCenterClient.self] }
		set { self[SecurityCenterClient.self] = newValue }
	}
}

// MARK: - SecurityCenterClient + TestDependencyKey
extension SecurityCenterClient: TestDependencyKey {
	public static let previewValue: Self = .noop

	public static let noop = Self(
		startMonitoring: {},
		problems: { _ in AsyncLazySequence([[]]).eraseToAnyAsyncSequence() },
		lastManualBackup: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		lastCloudBackup: { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)

	public static let testValue = Self(
		startMonitoring: unimplemented("\(Self.self).startMonitoring"),
		problems: unimplemented("\(Self.self).problems"),
		lastManualBackup: unimplemented("\(Self.self).lastManualBackup"),
		lastCloudBackup: unimplemented("\(Self.self).lastCloudBackup")
	)
}
