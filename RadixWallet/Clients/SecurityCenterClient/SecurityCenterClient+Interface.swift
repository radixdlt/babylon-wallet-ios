import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

// MARK: - SecurityCenterClient
public struct SecurityCenterClient: DependencyKey, Sendable {
	public let problems: Problems
	public let lastManualBackup: LastManualBackup
	public let lastCloudBackup: LastCloudBackup
}

// MARK: SecurityCenterClient.Problems
extension SecurityCenterClient {
	public typealias Problems = @Sendable () async -> AnyAsyncSequence<[SecurityProblem]>
	public typealias LastManualBackup = @Sendable () async -> AnyAsyncSequence<BackupStatus>
	public typealias LastCloudBackup = @Sendable () async -> AnyAsyncSequence<BackupStatus>
}

// MARK: - SecurityProblem
public enum SecurityProblem: Hashable, Sendable, Identifiable {
	case problem3(accounts: Int, personas: Int)
	case problem5
	case problem6
	case problem7
	case problem9

	public var id: Int { number }

	public var number: Int {
		switch self {
		case .problem3: 3
		case .problem5: 5
		case .problem6: 6
		case .problem7: 7
		case .problem9: 9
		}
	}
}

// MARK: - SecurityCenterClient.BackupStatus
extension SecurityCenterClient {
	// MARK: - BackupStatus
	public struct BackupStatus: Codable, Sendable {
		public let backupDate: Date
		public let upToDate: Bool
		public let success: Bool
	}
}
