import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewAccounts
struct TransactionReviewAccounts: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		init(accounts: IdentifiedArrayOf<TransactionReviewAccount.State>, enableCustomizeGuarantees: Bool) {
			self.accounts = accounts
			self.enableCustomizeGuarantees = enableCustomizeGuarantees
		}

		var accounts: IdentifiedArrayOf<TransactionReviewAccount.State>
		let enableCustomizeGuarantees: Bool
	}

	enum ViewAction: Sendable, Equatable {
		case customizeGuaranteesTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case account(id: AccountAddress, action: TransactionReviewAccount.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case showCustomizeGuarantees
		case showAsset(ResourceBalance, OnLedgerEntity.NonFungibleToken?)
	}

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.accounts, action: /Action.child .. ChildAction.account) {
				TransactionReviewAccount()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .customizeGuaranteesTapped:
			.send(.delegate(.showCustomizeGuarantees))
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .account(id: _, action: .delegate(.showAsset(transfer, token))):
			.send(.delegate(.showAsset(transfer, token)))
		case .account:
			.none
		}
	}
}

// MARK: - TransactionReviewAccount
struct TransactionReviewAccount: Sendable, FeatureReducer {
	struct State: Sendable, Identifiable, Hashable {
		var id: AccountAddress { account.address }
		let account: TransactionReview.ReviewAccount
		var transfers: IdentifiedArrayOf<TransactionReview.Transfer>
		let isDeposit: Bool

		init(account: TransactionReview.ReviewAccount, transfers: IdentifiedArrayOf<TransactionReview.Transfer>, isDeposit: Bool) {
			self.account = account
			self.transfers = transfers
			self.isDeposit = isDeposit
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case transferTapped(ResourceBalance, OnLedgerEntity.NonFungibleToken?)
	}

	enum DelegateAction: Sendable, Equatable {
		case showAsset(ResourceBalance, OnLedgerEntity.NonFungibleToken?)
		case showStakeClaim(OnLedgerEntitiesClient.StakeClaim)
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none
		case let .transferTapped(transfer, token):
			.send(.delegate(.showAsset(transfer, token)))
		}
	}
}
