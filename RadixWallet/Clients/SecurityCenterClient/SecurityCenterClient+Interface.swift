import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

// MARK: - SecurityCenterClient
public struct SecurityCenterClient: DependencyKey {
	public let problems: Problems
}

// MARK: SecurityCenterClient.Problems
extension SecurityCenterClient {
	public typealias Problems = () async throws -> [SecurityProblem]
}
