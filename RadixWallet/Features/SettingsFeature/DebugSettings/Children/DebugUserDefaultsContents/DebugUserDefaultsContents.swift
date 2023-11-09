import ComposableArchitecture
import SwiftUI

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
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case removeAllButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case removedAll
	}

	@Dependency(\.userDefaults) var userDefaults
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			loadKeyValues(into: &state)
			return .none

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

		case .mnemonicsUserClaimsToHaveBackedUp:
			return userDefaults.getFactorSourceIDOfBackedUpMnemonics().map(String.init(describing:))
		}
	}
}
