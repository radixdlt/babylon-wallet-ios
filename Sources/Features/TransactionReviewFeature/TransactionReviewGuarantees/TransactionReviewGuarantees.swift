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
		public var minimumPercentage: Double

		public init(
			account: TransactionReview.Account,
			transfer: TransactionReview.Transfer
		) {
			self.account = account
			self.transfer = transfer

			if let guaranteed = transfer.guarantee?.amount, guaranteed >= 0, guaranteed <= transfer.action.amount,
			   let minimumPercentage = try? (100 * guaranteed / transfer.action.amount).toDouble(withPrecision: 6)
			{
				self.minimumPercentage = minimumPercentage
			} else {
				self.minimumPercentage = 100
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case copyAddressTapped
		case increaseTapped
		case decreaseTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .copyAddressTapped:
			pasteboardClient.copyString(state.account.address.address)
			return .none

		case .increaseTapped:
			state.updateMinimumPercentage(with: state.minimumPercentage + percentageDelta)
			return .none

		case .decreaseTapped:
			state.updateMinimumPercentage(with: state.minimumPercentage - percentageDelta)
			return .none
		}
	}

	private let percentageDelta: Double = 0.1
}

extension TransactionReviewGuarantee.State {
	mutating func updateMinimumPercentage(with newPercentage: Double) {
		minimumPercentage = max(min(newPercentage, 100), 0)
		guard let newMinimumDecimal = BigDecimal(minimumPercentage * 0.01) else { return } // TODO: Handle?

		let newAmount = newMinimumDecimal * transfer.action.amount
		transfer.guarantee?.amount = newAmount
	}
}
