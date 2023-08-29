import ComposableArchitecture
import EngineKit
import FeaturePrelude

// MARK: - AccountDepositSettings
public struct AccountDepositSettings: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init(accounts: IdentifiedArrayOf<AccountDepositSettingsChange.State>) {
			self.accounts = accounts
		}

		public var accounts: IdentifiedArrayOf<AccountDepositSettingsChange.State>
	}

	public enum ViewAction: Sendable, Equatable {
		case customizeGuaranteesTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case account(id: AccountAddress.ID, action: AccountDepositSettingsChange.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case showAsset(OnLedgerEntity.Resource)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.accounts, action: /Action.child .. ChildAction.account) {
				AccountDepositSettingsChange()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .account(id: _, action: .delegate(.showAsset(let transfer))):
			return .send(.delegate(.showAsset(transfer)))
		case .account:
			return .none
		}
	}
}

// MARK: - AccountDepositSettingsChange
public struct AccountDepositSettingsChange: Sendable, FeatureReducer {
	public struct State: Sendable, Identifiable, Hashable {
		public struct ResourceChange: Sendable, Identifiable, Hashable {
			public enum Change: Sendable, Hashable {
				case resourcePreference(ResourcePreferenceAction)
				case authorizedDepositorAdded
				case authorizedDepositorRemoved
			}

			public var id: OnLedgerEntity.Resource {
				resource
			}

			public let resource: OnLedgerEntity.Resource
			public let change: Change

			public init(resource: OnLedgerEntity.Resource, change: Change) {
				self.resource = resource
				self.change = change
			}
		}

		public var id: AccountAddress.ID { account.address.id }
		public let account: Profile.Network.Account
		public let resourceChanges: IdentifiedArrayOf<ResourceChange>
		public let depositRuleChange: AccountDefaultDepositRule?

		public init(account: Profile.Network.Account, depositRuleChange: AccountDefaultDepositRule?, resourceChanges: IdentifiedArrayOf<ResourceChange>) {
			self.account = account
			self.depositRuleChange = depositRuleChange
			self.resourceChanges = resourceChanges
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case assetTapped(OnLedgerEntity.Resource)
	}

	public enum DelegateAction: Sendable, Equatable {
		case showAsset(OnLedgerEntity.Resource)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .assetTapped(asset):
			return .send(.delegate(.showAsset(asset)))
		}
	}
}
