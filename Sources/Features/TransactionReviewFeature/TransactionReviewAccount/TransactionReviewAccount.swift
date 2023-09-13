import ComposableArchitecture
import EngineKit
import FeaturePrelude

// MARK: - TransactionReviewAccounts
public struct TransactionReviewAccounts: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init(accounts: IdentifiedArrayOf<TransactionReviewAccount.State>, enableCustomizeGuarantees: Bool) {
			self.accounts = accounts
			self.enableCustomizeGuarantees = enableCustomizeGuarantees
		}

		public var accounts: IdentifiedArrayOf<TransactionReviewAccount.State>
		public let enableCustomizeGuarantees: Bool
	}

	public enum ViewAction: Sendable, Equatable {
		case customizeGuaranteesTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case account(id: AccountAddress.ID, action: TransactionReviewAccount.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case showCustomizeGuarantees
		case showAsset(TransactionReview.Transfer)
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.accounts, action: /Action.child .. ChildAction.account) {
				TransactionReviewAccount()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .customizeGuaranteesTapped:
			return .send(.delegate(.showCustomizeGuarantees))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .account(id: _, action: .delegate(.showAsset(let transfer))):
			return .send(.delegate(.showAsset(transfer)))
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
		case transferTapped(TransactionReview.Transfer)
	}

	public enum DelegateAction: Sendable, Equatable {
		case showAsset(TransactionReview.Transfer)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case let .transferTapped(transfer):
			return .send(.delegate(.showAsset(transfer)))
		}
	}
}
