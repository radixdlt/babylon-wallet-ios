import ComposableArchitecture
import EngineKit
import FeaturePrelude

// MARK: - AccountDepositSettings
public struct AccountDepositSettings: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init(accounts: IdentifiedArrayOf<AccountDepositSettingsChange>) {
			self.accounts = accounts
		}

		public var accounts: IdentifiedArrayOf<AccountDepositSettingsChange>
	}

	public init() {}
}

// MARK: - AccountDepositSettingsChange
public struct AccountDepositSettingsChange: Sendable, Identifiable, Hashable {
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

extension AccountDepositSettingsChange {
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
