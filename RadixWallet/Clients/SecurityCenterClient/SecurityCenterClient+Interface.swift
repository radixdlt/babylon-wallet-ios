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
	typealias Problems = @Sendable (SecurityProblemKind?) async -> AnyAsyncSequence<[SecurityProblem]>
	typealias LastManualBackup = @Sendable () async -> AnyAsyncSequence<BackupStatus?>
	typealias LastCloudBackup = @Sendable () async -> AnyAsyncSequence<BackupStatus?>
}

// MARK: - SecurityProblem
extension SecurityProblem {
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
