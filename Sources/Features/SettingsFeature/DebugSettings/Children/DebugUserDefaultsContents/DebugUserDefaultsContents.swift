import FaucetClient //  EpochForWhenLastUsedByAccountAddress
import FeaturePrelude

// MARK: - DebugUserDefaultsContents
public struct DebugUserDefaultsContents: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public struct KeyValues: Sendable, Hashable, Identifiable {
			public var id: String { key.rawValue }
			public let key: UserDefaultsClient.Key
			public let values: [String]
			public init(key: UserDefaultsClient.Key, values: [String]) {
				self.key = key
				self.values = values
			}
		}

		public var keyedValues: IdentifiedArrayOf<KeyValues> = []
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	@Dependency(\.userDefaultsClient) var userDefaultsClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			state.keyedValues = IdentifiedArrayOf(uniqueElements: UserDefaultsClient.Key.allCases.map {
				DebugUserDefaultsContents.State.KeyValues(
					key: $0,
					values: $0.valuesForKey()
				)
			})
			return .none
		}
	}
}

extension UserDefaultsClient.Key {
	func valuesForKey() -> [String] {
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		switch self {
		case .accountsThatNeedRecovery:
			return userDefaultsClient.getAddressesOfAccountsThatNeedRecovery().map(\.address)
		case .activeProfileID:
			guard let value = userDefaultsClient.stringForKey(.activeProfileID) else {
				return []
			}
			return [value]
		case .epochForWhenLastUsedByAccountAddress:
			return userDefaultsClient.loadEpochForWhenLastUsedByAccountAddress().epochForAccounts.map { "epoch: \($0.epoch) account: \($0.accountAddress)" }
		case .hideMigrateOlympiaButton:
			return [userDefaultsClient.hideMigrateOlympiaButton].map(String.init(describing:))

		case .mnemonicsUserClaimsToHaveBackedUp:
			return userDefaultsClient.getFactorSourceIDOfBackedUpMnemonics().map(String.init(describing:))
		}
	}
}
