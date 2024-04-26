import CloudKit
import ComposableArchitecture

public struct ConfigurationBackup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var iCLoudAccountStatus: CKAccountStatus? = nil
		public var automatedBackupsEnabled: Bool = true
		public var problems: [SecurityProblem] = [.problem5]
		public var lastBackup: Date? = nil

		public var outdatedBackupPresent: Bool {
			!automatedBackupsEnabled && lastBackup != nil
		}

		public var actionsRequired: [Item] {
			problems.isEmpty ? [] : Item.allCases
		}
	}

	public enum Item: Sendable, Hashable, CaseIterable {
		case accounts
		case personas
		case securityFactors
		case walletSettings
	}

	public enum ViewAction: Sendable, Equatable {
		case onAppear
		case toggleAutomatedBackups(Bool)
		case exportTapped
		case deleteOutdatedTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case isCloudBackupEnabled(Bool)
		case iCloudAccountStatus(CKAccountStatus)
		case lastBackedUp(Date?)
		case outdatedBackupDeleted(Profile.ID)
	}

	@Dependency(\.cloudBackupClient) var cloudBackupClient

	private func checkCloudBackupEnabledEffect() -> Effect<Action> {
		.run { send in
			let profile = await ProfileStore.shared.profile
			let networkProfile = try profile.network(id: profile.networkID)
			let iCloudEnabled = profile.appPreferences.security.isCloudProfileSyncEnabled
			await send(.internal(.isCloudBackupEnabled(iCloudEnabled)))
		} catch: { _, _ in
		}
	}

	private func checkCloudAccountStatusEffect() -> Effect<Action> {
		.run { send in
			let status = try await cloudBackupClient.checkAccountStatus()
			await send(.internal(.iCloudAccountStatus(status)))
		} catch: { _, _ in
		}
	}

	private func updateLastBackupEffect() -> Effect<Action> {
		.run { send in
			let profile = await ProfileStore.shared.profile
			do {
				let lastBackedUp = try await cloudBackupClient.lastBackup(profile.id)
				await send(.internal(.lastBackedUp(lastBackedUp)))
				print("•• got last backed up")
			} catch {
				loggerGlobal.error("Failed to fetch last backup for \(profile.id.uuidString): \(error)")
			}
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onAppear:
			return updateLastBackupEffect()

		case let .toggleAutomatedBackups(isEnabled):
			state.automatedBackupsEnabled = isEnabled
			if isEnabled {
				state.lastBackup = nil
			} else {
				// FIXME: GK - turn off backups
			}
			return updateLastBackupEffect()

		case .exportTapped:
			return .none

		case .deleteOutdatedTapped:

			return .run { send in
				let profile = await ProfileStore.shared.profile
				do {
					try await cloudBackupClient.deleteProfile(profile.id)
					await send(.internal(.outdatedBackupDeleted(profile.id)))
					await send(.internal(.lastBackedUp(nil)))
					print("•• deleted outdate \(profile.id)")
				} catch {
					loggerGlobal.error("Failed to delete outdate backup \(profile.id.uuidString): \(error)")
				}
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .lastBackedUp(date):
			state.lastBackup = date
			return .none

		case let .outdatedBackupDeleted(id):
			// FIXME: GK - show alert? toast?
			return .none

		case let .isCloudBackupEnabled(isEnabled):
			state.automatedBackupsEnabled = isEnabled
			return .none

		case let .iCloudAccountStatus(status):
			state.iCLoudAccountStatus = status
			return .none
		}
	}
}
