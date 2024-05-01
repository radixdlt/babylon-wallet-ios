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
		problems: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)

	public static let testValue = Self(
		problems: unimplemented("\(Self.self).problems")
	)
}
