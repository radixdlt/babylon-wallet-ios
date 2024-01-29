import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewGuarantees
public struct TransactionReviewGuarantees: Sendable, FeatureReducer {
	@Dependency(\.dismiss) var dismiss

	public struct State: Sendable, Hashable {
		public var guarantees: IdentifiedArrayOf<TransactionReviewGuarantee.State>

		public var isValid: Bool {
			guarantees.allSatisfy(\.percentageStepper.isValid)
		}

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
		case applyGuarantees(IdentifiedArrayOf<TransactionReviewGuarantee.State>)
	}

	public init() {}

	public var body: some ReducerOf<TransactionReviewGuarantees> {
		Reduce(core)
			.forEach(\.guarantees, action: /Action.child .. /ChildAction.guarantee) {
				TransactionReviewGuarantee()
			}
			.ifLet(\.$info, action: /Action.child .. /ChildAction.info) {
				SlideUpPanel()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .infoTapped:
			// FIXME: For mainnet
			//			state.info = .init(title: L10n.TransactionReview.Guarantees.explanationTitle,
			//			                   explanation: L10n.TransactionReview.Guarantees.explanationText)
			return .none

		case .applyTapped:
			let guarantees = state.guarantees
			return .run { send in
				await send(.delegate(.applyGuarantees(guarantees)))
				await dismiss()
			}

		case .closeTapped:
			return .run { _ in
				await dismiss()
			}
		}
	}
}

// MARK: - TransactionReviewGuarantee
public struct TransactionReviewGuarantee: Sendable, FeatureReducer {
	public struct State: Identifiable, Sendable, Hashable {
		public let id: TransactionReview.Transfer.ID
		public let account: TransactionReview.Account
		public let resource: OnLedgerEntity.Resource
		public var details: TransactionReview.Transfer.Details.Fungible

		public var percentageStepper: MinimumPercentageStepper.State

		init?(
			account: TransactionReview.Account,
			transfer: TransactionReview.Transfer
		) {
			guard case let .fungible(details) = transfer.details, details.amount > 0 else { return nil }
			guard let guarantee = details.guarantee, guarantee.amount >= 0 else { return nil }

			self.id = transfer.id
			self.account = account
			self.resource = transfer.resource
			self.details = details
			self.percentageStepper = .init(value: 100 * guarantee.amount / details.amount)

			updateAmount()
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case percentageStepper(MinimumPercentageStepper.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.percentageStepper, action: /Action.child .. /ChildAction.percentageStepper) {
			MinimumPercentageStepper()
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .percentageStepper(.delegate(.valueChanged)):
			state.updateAmount()
			return .none

		case .percentageStepper:
			return .none
		}
	}
}

extension TransactionReviewGuarantee.State {
	mutating func updateAmount() {
		guard let value = percentageStepper.value else { return }

		let newMinimumDecimal = value * 0.01
		let divisibility = resource.divisibility.map(UInt.init) ?? RETDecimal.maxDivisibility
		let newAmount = (newMinimumDecimal * details.amount).rounded(decimalPlaces: divisibility)
		details.guarantee?.amount = newAmount
	}
}
