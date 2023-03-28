import ComposableArchitecture
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
}

// MARK: - TransactionReviewAccount
public struct TransactionReviewAccount: Sendable, FeatureReducer {
	@Dependency(\.pasteboardClient) private var pasteboardClient

	public struct State: Sendable, Identifiable, Hashable {
		public var id: AccountAddress.ID { account.address.id }
		public let account: TransactionReview.Account
		public let transfers: [TransactionReview.Transfer]

		public init(account: TransactionReview.Account, transfers: [TransactionReview.Transfer]) {
			self.account = account
			self.transfers = transfers
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case copyAddress
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .copyAddress:
			pasteboardClient.copyString(state.account.address.address)
			return .none
		}
	}
}
