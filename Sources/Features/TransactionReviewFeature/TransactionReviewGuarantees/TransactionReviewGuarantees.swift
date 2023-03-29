import FeaturePrelude

// MARK: - TransactionReviewGuarantees
public struct TransactionReviewGuarantees: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var guarantees: IdentifiedArrayOf<TransactionReviewGuarantee.State>

		@PresentationState
		public var info: SlideUpPanel.State?

		public init(guarantees: IdentifiedArrayOf<TransactionReviewGuarantee.State>) {
			self.guarantees = guarantees
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case infoTapped
		case applyTapped
		case closeTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case guarantee(id: TransactionReviewGuarantee.State.ID, action: TransactionReviewGuarantee.Action)
		case info(PresentationAction<SlideUpPanel.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss(apply: Bool)
	}

	public init() {}

	public var body: some ReducerProtocolOf<TransactionReviewGuarantees> {
		Reduce(core)
			.forEach(\.guarantees, action: /Action.child .. /ChildAction.guarantee) {
				TransactionReviewGuarantee()
			}
			.ifLet(\.$info, action: /Action.child .. /ChildAction.info) {
				SlideUpPanel()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .infoTapped:
//			state.info = .init(title: L10n.TransactionReview.Guarantees.explanationTitle,
//			                   explanation: L10n.TransactionReview.Guarantees.explanationText)
			return .none

		case .applyTapped:
			return .send(.delegate(.dismiss(apply: true)))

		case .closeTapped:
			return .send(.delegate(.dismiss(apply: false)))
		}
	}
}

// MARK: - TransactionReviewGuarantee
public struct TransactionReviewGuarantee: Sendable, FeatureReducer {
	@Dependency(\.pasteboardClient) var pasteboardClient

	public struct State: Identifiable, Sendable, Hashable {
		public var id: AccountAction { transfer.id }
		public let account: TransactionReview.Account

		public var transfer: TransactionReview.Transfer
		public var percentageStepper: MinimumPercentageStepper.State

		public init(
			account: TransactionReview.Account,
			transfer: TransactionReview.Transfer
		) {
			self.account = account
			self.transfer = transfer

			if let guaranteed = transfer.guarantee?.amount, guaranteed >= 0, guaranteed <= transfer.action.amount {
				self.percentageStepper = .init(value: 100 * guaranteed / transfer.action.amount)
			} else {
				self.percentageStepper = .init(value: 100)
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case copyAddressTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case percentageStepper(MinimumPercentageStepper.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.percentageStepper, action: /Action.child .. /ChildAction.percentageStepper) {
			MinimumPercentageStepper()
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .copyAddressTapped:
			pasteboardClient.copyString(state.account.address.address)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .percentageStepper:
			let newMinimumDecimal = state.percentageStepper.value * 0.01
			let newAmount = newMinimumDecimal * state.transfer.action.amount

			state.transfer.guarantee?.amount = newAmount

			return .none
		}
	}
}
