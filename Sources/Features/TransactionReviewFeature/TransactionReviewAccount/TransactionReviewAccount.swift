import ComposableArchitecture
import EngineKit
import FeaturePrelude

// MARK: - TransactionReviewAccounts
public struct TransactionReviewAccounts: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init(accounts: IdentifiedArrayOf<TransactionReviewAccount.State>, showCustomizeGuarantees: Bool) {
			self.accounts = accounts
			self.showCustomizeGuarantees = showCustomizeGuarantees
		}

		public var accounts: IdentifiedArrayOf<TransactionReviewAccount.State>
		public let showCustomizeGuarantees: Bool
	}

	public enum ViewAction: Sendable, Equatable {
		case customizeGuaranteesTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case account(id: AccountAddress.ID, action: TransactionReviewAccount.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case showCustomizeGuarantees
		case showAsset(ResourceAddress)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.accounts, action: /Action.child .. ChildAction.account) {
				TransactionReviewAccount()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .customizeGuaranteesTapped:
			return .send(.delegate(.showCustomizeGuarantees))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .account(id: _, action: .delegate(.showAsset(let resource))):
			return .send(.delegate(.showAsset(resource)))
		case .account:
			return .none
		}
	}
}

// MARK: - TransactionReviewAccount
public struct TransactionReviewAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Identifiable, Hashable {
		public var id: AccountAddress.ID { account.address.id }
		public let account: TransactionReview.Account
		public var transfers: IdentifiedArrayOf<TransactionReview.Transfer>

		public init(account: TransactionReview.Account, transfers: IdentifiedArrayOf<TransactionReview.Transfer>) {
			self.account = account
			self.transfers = transfers
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case assetTapped(ResourceAddress)
	}

	public enum DelegateAction: Sendable, Equatable {
		case showAsset(ResourceAddress)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case let .assetTapped(resource):
			return .send(.delegate(.showAsset(resource)))
		}
	}
}
