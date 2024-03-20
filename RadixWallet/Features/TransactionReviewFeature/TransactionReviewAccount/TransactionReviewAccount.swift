import ComposableArchitecture
import SwiftUI

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

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case account(id: AccountAddress, action: TransactionReviewAccount.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case showCustomizeGuarantees
		case showAsset(ResourceBalance, OnLedgerEntity.NonFungibleToken?)
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
			.send(.delegate(.showCustomizeGuarantees))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .account(id: _, action: .delegate(.showAsset(transfer, token))):
			.send(.delegate(.showAsset(transfer, token)))
		case .account:
			.none
		}
	}
}

// MARK: - TransactionReviewAccount
public struct TransactionReviewAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Identifiable, Hashable {
		public var id: AccountAddress { account.address }
		public let account: TransactionReview.Account
		public var transfers: IdentifiedArrayOf<TransactionReview.Transfer>

		public init(account: TransactionReview.Account, transfers: IdentifiedArrayOf<TransactionReview.Transfer>) {
			self.account = account
			self.transfers = transfers
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case transferTapped(ResourceBalance, OnLedgerEntity.NonFungibleToken?)
	}

	public enum DelegateAction: Sendable, Equatable {
		case showAsset(ResourceBalance, OnLedgerEntity.NonFungibleToken?)
		case showStakeClaim(OnLedgerEntitiesClient.StakeClaim)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none
		case let .transferTapped(transfer, token):
			.send(.delegate(.showAsset(transfer, token)))
		}
	}
}
