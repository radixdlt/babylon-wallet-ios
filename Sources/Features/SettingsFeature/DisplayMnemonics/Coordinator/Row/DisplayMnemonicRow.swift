import FeaturePrelude

// MARK: - DisplayMnemonicRow
public struct DisplayMnemonicRow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = AccountsForDeviceFactorSource.ID
		public var id: ID { accountsForDeviceFactorSource.id }
		public var deviceFactorSource: HDOnDeviceFactorSource { accountsForDeviceFactorSource.deviceFactorSource }

		public let accountsForDeviceFactorSource: AccountsForDeviceFactorSource

		public init(accountsForDeviceFactorSource: AccountsForDeviceFactorSource) {
			self.accountsForDeviceFactorSource = accountsForDeviceFactorSource
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case tapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case openDetails
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .tapped:
			return .send(.delegate(.openDetails))
		}
	}
}
