import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

// MARK: - SecurityCenterClient
struct SecurityCenterClient: DependencyKey, Sendable {
	let startMonitoring: StartMonitoring
	let problems: Problems
	let lastManualBackup: LastManualBackup
	let lastCloudBackup: LastCloudBackup
}

// MARK: SecurityCenterClient.Problems
extension SecurityCenterClient {
	typealias StartMonitoring = @Sendable () async throws -> Void
	typealias Problems = @Sendable (SecurityProblem.ProblemType?) async -> AnyAsyncSequence<[SecurityProblem]>
	typealias LastManualBackup = @Sendable () async -> AnyAsyncSequence<BackupStatus?>
	typealias LastCloudBackup = @Sendable () async -> AnyAsyncSequence<BackupStatus?>
}

// MARK: - SecurityProblem
/// As outlined in https://radixdlt.atlassian.net/wiki/spaces/AT/pages/3392569357/Security-related+Problem+States+in+the+Wallet
enum SecurityProblem: Hashable, Sendable, Identifiable {
	/// The given addresses of `accounts` and `personas` are unrecoverable if the user loses their phone, since their corresponding seed phrase has not been written down.
	/// NOTE: This definition differs from the one at Confluence since we don't have shields implemented yet.
	case problem3(addresses: AddressesOfEntitiesInBadState)
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
	case problem9(addresses: AddressesOfEntitiesInBadState)

	var id: Int { number }

	var number: Int {
		switch self {
		case .problem3: 3
		case .problem5: 5
		case .problem6: 6
		case .problem7: 7
		case .problem9: 9
		}
	}

	var accountCard: String {
		switch self {
		case .problem3: L10n.SecurityProblems.No3.accountCard
		case .problem5: L10n.SecurityProblems.No5.accountCard
		case .problem6: L10n.SecurityProblems.No6.accountCard
		case .problem7: L10n.SecurityProblems.No7.accountCard
		case .problem9: L10n.SecurityProblems.No9.accountCard
		}
	}

	var walletSettingsSecurityCenter: String {
		securityCenterTitle
	}

	var securityCenterTitle: String {
		switch self {
		case let .problem3(addresses): problem3(addresses: addresses)
		case .problem5: L10n.SecurityProblems.No5.securityCenterTitle
		case .problem6: L10n.SecurityProblems.No6.securityCenterTitle
		case .problem7: L10n.SecurityProblems.No7.securityCenterTitle
		case .problem9: L10n.SecurityProblems.No9.securityCenterTitle
		}
	}

	private func problem3(addresses: AddressesOfEntitiesInBadState) -> String {
		typealias Common = L10n.SecurityProblems.Common
		typealias Problem = L10n.SecurityProblems.No3
		let hasHidden = addresses.hiddenAccounts.count + addresses.hiddenPersonas.count > 0
		let accounts = addresses.accounts.count == 1 ? Common.accountSingular : Common.accountPlural(addresses.accounts.count)
		let personas = addresses.personas.count == 1 ? Common.personaSingular : Common.personaPlural(addresses.personas.count)
		return hasHidden ? Problem.securityCenterTitleHidden(accounts, personas) : Problem.securityCenterTitle(accounts, personas)
	}

	var securityCenterBody: String {
		switch self {
		case .problem3: L10n.SecurityProblems.No3.securityCenterBody
		case .problem5: L10n.SecurityProblems.No5.securityCenterBody
		case .problem6: L10n.SecurityProblems.No6.securityCenterBody
		case .problem7: L10n.SecurityProblems.No7.securityCenterBody
		case .problem9: L10n.SecurityProblems.No9.securityCenterBody
		}
	}

	var configurationBackup: String? {
		switch self {
		case .problem3: nil
		case .problem5: L10n.SecurityProblems.No5.configurationBackup
		case .problem6: L10n.SecurityProblems.No6.configurationBackup
		case .problem7: L10n.SecurityProblems.No7.configurationBackup
		case .problem9: nil
		}
	}

	var securityFactors: String? {
		switch self {
		case .problem3: L10n.SecurityProblems.No3.securityFactors
		case .problem5: nil
		case .problem6: nil
		case .problem7: nil
		case .problem9: L10n.SecurityProblems.No9.securityFactors
		}
	}

	var seedPhrases: String? {
		switch self {
		case .problem3: L10n.SecurityProblems.No3.seedPhrases
		case .problem5: nil
		case .problem6: nil
		case .problem7: nil
		case .problem9: L10n.SecurityProblems.No9.seedPhrases
		}
	}

	var walletSettingsPersonas: String {
		switch self {
		case .problem3: L10n.SecurityProblems.No3.walletSettingsPersonas
		case .problem5: L10n.SecurityProblems.No5.walletSettingsPersonas
		case .problem6: L10n.SecurityProblems.No6.walletSettingsPersonas
		case .problem7: L10n.SecurityProblems.No7.walletSettingsPersonas
		case .problem9: L10n.SecurityProblems.No9.walletSettingsPersonas
		}
	}

	var personas: String {
		switch self {
		case .problem3: L10n.SecurityProblems.No3.personas
		case .problem5: L10n.SecurityProblems.No5.personas
		case .problem6: L10n.SecurityProblems.No6.personas
		case .problem7: L10n.SecurityProblems.No7.personas
		case .problem9: L10n.SecurityProblems.No9.personas
		}
	}

	var type: ProblemType {
		switch self {
		case .problem3, .problem9: .securityFactors
		case .problem5, .problem6, .problem7: .configurationBackup
		}
	}

	enum ProblemType: Hashable, Sendable, CaseIterable {
		case securityFactors
		case configurationBackup
	}
}

// MARK: - BackupStatus
struct BackupStatus: Hashable, Codable, Sendable {
	let result: BackupResult
	let isCurrent: Bool

	init(result: BackupResult, profile: Profile) {
		self.result = result
		self.isCurrent = result.saveIdentifier == profile.header.saveIdentifier
	}
}
