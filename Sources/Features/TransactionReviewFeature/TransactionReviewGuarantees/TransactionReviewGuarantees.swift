import FeaturePrelude

// MARK: - TransactionReviewGuarantees
public struct TransactionReviewGuarantees: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var guarantees: IdentifiedArrayOf<TransactionReviewGuarantee.State>

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
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .infoTapped:
			// TODO: Show some info
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
	public struct State: Identifiable, Sendable, Hashable {
		public var id: AccountAction { transfer.id }
		public let account: TransactionReview.Account
		public let accountIfVisible: TransactionReview.Account?

		public var transfer: TransactionReview.Transfer
		public var minimumPercentage: Double
	}

	public enum ViewAction: Sendable, Equatable {
		case increaseTapped
		case decreaseTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .increaseTapped:
			state.updateMinimumPercentage(with: state.minimumPercentage + percentageDelta)
			return .none
		case .decreaseTapped:
			state.updateMinimumPercentage(with: state.minimumPercentage - percentageDelta)
			return .none
		}
	}

	private let percentageDelta: Double = 5
}

extension TransactionReviewGuarantee.State {
	mutating func updateMinimumPercentage(with newPercentage: Double) {
		let newMinimum = max(min(newPercentage * 0.01, 1), 0)
		guard let newMinimumDecimal = BigDecimal(newMinimum) else { return } // TODO: Handle?

		minimumPercentage = newPercentage
		transfer.metadata.guarantee?.amount = newMinimumDecimal * transfer.action.amount
	}
}
