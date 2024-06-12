import ComposableArchitecture
import SwiftUI

private let stringValuesTestKey = "stringValuesTestKey"

// MARK: - DebugUserDefaultsContents
public struct DebugUserDefaultsContents: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public struct KeyValues: Sendable, Hashable, Identifiable {
			public var id: String { key.rawValue }
			public let key: UserDefaults.Dependency.Key
			public let values: [String]
			public init(key: UserDefaults.Dependency.Key, values: [String]) {
				self.key = key
				self.values = values
			}
		}

		public var keyedValues: IdentifiedArrayOf<KeyValues> = []
		public var stringValuesOverTime: [String] = []
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case removeAllButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case removedAll
		case gotStringValue(String)
	}

	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.uuid) var uuid
	@Dependency(\.continuousClock) var clock
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			loadKeyValues(into: &state)
			return .run { send in
				for await string in userDefaults.stringValues(forKey: stringValuesTestKey) {
					guard !Task.isCancelled else { return }
					await send(.internal(.gotStringValue(string ?? "<NIL>")))
				}
			}
			.merge(with: .run { _ in
				@Sendable func emit() async {
					try? await clock.sleep(for: .seconds(0.5))
					guard !Task.isCancelled else { return }
					userDefaults.set(uuid().uuidString, forKey: stringValuesTestKey)
					await emit()
				}
				await emit()
			})

		case .removeAllButtonTapped:
			return .run { send in
				userDefaults.removeAll(but: [.activeProfileID])
				await send(.internal(.removedAll))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .removedAll:
			loadKeyValues(into: &state)
			return .none
		case let .gotStringValue(stringValue):
			state.stringValuesOverTime.append(stringValue)
			return .none
		}
	}

	private func loadKeyValues(into state: inout State) {
		state.keyedValues = IdentifiedArrayOf(uniqueElements: UserDefaults.Dependency.Key.allCases.map {
			DebugUserDefaultsContents.State.KeyValues(
				key: $0,
				values: $0.valuesForKey()
			)
		})
	}
}

extension UserDefaults.Dependency.Key {
	func valuesForKey() -> [String] {
		@Dependency(\.userDefaults) var userDefaults
		switch self {
		case .activeProfileID:
			guard let value = userDefaults.string(key: .activeProfileID) else {
				return []
			}
			return [value]
		case .epochForWhenLastUsedByAccountAddress:
			return userDefaults.loadEpochForWhenLastUsedByAccountAddress().epochForAccounts.map { "epoch: \($0.epoch) account: \($0.accountAddress)" }

		case .hideMigrateOlympiaButton:
			return [userDefaults.hideMigrateOlympiaButton].map(String.init(describing:))

		case .showRadixBanner:
			return [userDefaults.showRadixBanner].map(String.init(describing:))

		case .mnemonicsUserClaimsToHaveBackedUp:
			return userDefaults.getFactorSourceIDOfBackedUpMnemonics().map(String.init(describing:))
		case .transactionsCompletedCounter:
			return userDefaults.getTransactionsCompletedCounter().map(String.init(describing:)).asArray(\.self)
		case .dateOfLastSubmittedNPSSurvey:
			return userDefaults.getDateOfLastSubmittedNPSSurvey().map(String.init(describing:)).asArray(\.self)
		case .npsSurveyUserID:
			return userDefaults.getNPSSurveyUserId().map(String.init(describing:)).asArray(\.self)
		case .dAppLinkingAutoContinueEnabled:
			return [String(userDefaults.getDappLinkingAutoContinueEnabled())]
		case .migratedKeychainProfiles:
			return userDefaults.getMigratedKeychainProfiles.map(\.uuidString)
		case .lastCloudBackups:
			return userDefaults.getLastCloudBackups.map { "\($0.key.uuidString): \(String(describing: $0.value))" }
		case .lastManualBackups:
			return userDefaults.getLastManualBackups.map { "\($0.key.uuidString): \(String(describing: $0.value))" }
		case .lastSyncedAccountsWithCE:
			return userDefaults.getLastSyncedAccountsWithCE().asArray(\.self)
		case .showRelinkConnectorsAfterUpdate:
			return [userDefaults.showRelinkConnectorsAfterUpdate].map(String.init(describing:))
		case .showRelinkConnectorsAfterProfileRestore:
			return [userDefaults.showRelinkConnectorsAfterProfileRestore].map(String.init(describing:))
		}
	}
}
