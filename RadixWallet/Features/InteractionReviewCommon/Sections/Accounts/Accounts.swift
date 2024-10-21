import ComposableArchitecture
import SwiftUI

// MARK: - InteractionReviewCommon.Accounts
extension InteractionReviewCommon {
	@Reducer
	struct Accounts: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			init(accounts: IdentifiedArrayOf<InteractionReviewCommon.Account.State>, enableCustomizeGuarantees: Bool) {
				self.accounts = accounts
				self.enableCustomizeGuarantees = enableCustomizeGuarantees
			}

			var accounts: IdentifiedArrayOf<InteractionReviewCommon.Account.State>
			let enableCustomizeGuarantees: Bool
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case customizeGuaranteesTapped
		}

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case account(id: AccountAddress, action: InteractionReviewCommon.Account.Action)
		}

		enum DelegateAction: Sendable, Equatable {
			case showCustomizeGuarantees
			case showAsset(ResourceBalance, OnLedgerEntity.NonFungibleToken?)
		}

		var body: some ReducerOf<Self> {
			Reduce(core)
				.forEach(\.accounts, action: /Action.child .. ChildAction.account) {
					InteractionReviewCommon.Account()
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
}

// MARK: - InteractionReviewCommon.Account
extension InteractionReviewCommon {
	@Reducer
	struct Account: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Identifiable, Hashable {
			var id: AccountAddress { account.address }

			let account: InteractionReviewCommon.ReviewAccount
			var transfers: IdentifiedArrayOf<InteractionReviewCommon.Transfer>
			let isDeposit: Bool
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case appeared
			case transferTapped(ResourceBalance, OnLedgerEntity.NonFungibleToken?)
		}

		enum DelegateAction: Sendable, Equatable {
			case showAsset(ResourceBalance, OnLedgerEntity.NonFungibleToken?)
			case showStakeClaim(OnLedgerEntitiesClient.StakeClaim)
		}

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .appeared:
				.none
			case let .transferTapped(transfer, token):
				.send(.delegate(.showAsset(transfer, token)))
			}
		}
	}
}

// Neccessary so that ReviewAccount.user has a proper Account associated (and not the InteractionReviewCommon.Account reducer)
typealias RadixAccount = Account

// MARK: - InteractionReviewCommon.ReviewAccount
extension InteractionReviewCommon {
	enum ReviewAccount: Sendable, Hashable {
		case user(RadixAccount)
		case external(AccountAddress, approved: Bool)

		var address: AccountAddress {
			switch self {
			case let .user(account):
				account.address
			case let .external(address, _):
				address
			}
		}

		var isApproved: Bool {
			switch self {
			case .user:
				false
			case let .external(_, approved):
				approved
			}
		}
	}
}
