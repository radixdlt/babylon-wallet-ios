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
	public typealias LastManualBackup = @Sendable () async -> AnyAsyncSequence<BackupStatus?>
	public typealias LastCloudBackup = @Sendable () async -> AnyAsyncSequence<BackupStatus?>
}

// MARK: - SecurityProblem
/// As outlined in https://radixdlt.atlassian.net/wiki/spaces/AT/pages/3392569357/Security-related+Problem+States+in+the+Wallet
public enum SecurityProblem: Hashable, Sendable, Identifiable {
	/// User has at least one shield, but has no XRD. User has an account (or accounts) without a shield applied, meaning it is only secured by a single factor.
	/// That factor (as is often, but not always the case) is a phone key factor and the user has never viewed the seed phrase and confirmed that they wrote it down.
	/// Losing the phone means losing that account forever.
	case problem3(accounts: Int, personas: Int)
	/// Wallet backups to the cloud aren’t working (wallet tried to do a backup and it didn’t work within, say, 5 minutes.)
	/// This means that currently all accounts and personas are at risk of being practically unrecoverable if the user loses their phone.
	/// Also they would lose all of their other non-security wallet settings and data.
	case problem5
	/// Cloud backups are turned off  and user has never done a manual file export. This means that currently all accounts and personas  are at risk of
	/// being practically unrecoverable if the user loses their phone. Also they would lose all of their other non-security wallet settings and data.
	case problem6
	/// Cloud backups are turned off and user previously did a manual file export, but has made a change and haven’t yet re-exported a file backup that
	/// includes that change. This means that any changes made will be lost if the user loses their phone - including control of new accounts/personas they’ve
	/// created, as well as changed settings or changed/added data.
	case problem7
	/// User has gotten a new phone (and restored their wallet from backup) and the wallet sees that there are accounts without shields using a phone key,
	/// meaning they can only be recovered with the seed phrase. (See problem 2) This would also be the state if a user disabled their PIN (and reenabled it), clearing phone keys.
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
	public struct BackupStatus: Hashable, Codable, Sendable {
		public let backupDate: Date
		public let upToDate: Bool
		public let success: Bool
	}
}
