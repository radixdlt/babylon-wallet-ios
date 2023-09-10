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
		public var id: AccountAddress.ID { account.address.id }
		public let account: Profile.Network.Account
		public let resourceChanges: IdentifiedArrayOf<ResourcePreferenceChange>
		public let allowedDepositorChanges: IdentifiedArrayOf<AllowedDepositorChange>
		public let depositRuleChange: AccountDefaultDepositRule?

		public init(
			account: Profile.Network.Account,
			depositRuleChange: AccountDefaultDepositRule?,
			resourceChanges: IdentifiedArrayOf<ResourcePreferenceChange>,
			allowedDepositorChanges: IdentifiedArrayOf<AllowedDepositorChange>
		) {
			self.account = account
			self.depositRuleChange = depositRuleChange
			self.resourceChanges = resourceChanges
			self.allowedDepositorChanges = allowedDepositorChanges
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

extension AccountDepositSettingsChange.State {
	public struct ResourcePreferenceChange: Sendable, Identifiable, Hashable {
		public var id: OnLedgerEntity.Resource {
			resource
		}

		public let resource: OnLedgerEntity.Resource
		public let change: ResourcePreferenceAction

		public init(resource: OnLedgerEntity.Resource, preferenceChange: ResourcePreferenceAction) {
			self.resource = resource
			self.change = preferenceChange
		}
	}

	public struct AllowedDepositorChange: Sendable, Identifiable, Hashable {
		public enum Change: Sendable, Hashable {
			case added
			case removed
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
}
