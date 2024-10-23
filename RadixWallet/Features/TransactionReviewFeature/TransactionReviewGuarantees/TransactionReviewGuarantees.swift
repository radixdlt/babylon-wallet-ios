import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewGuarantees
struct TransactionReviewGuarantees: Sendable, FeatureReducer {
	@Dependency(\.dismiss) var dismiss

	struct State: Sendable, Hashable {
		var guarantees: IdentifiedArrayOf<TransactionReviewGuarantee.State>

		var isValid: Bool {
			guarantees.allSatisfy(\.percentageStepper.isValid)
		}

		init(guarantees: IdentifiedArrayOf<TransactionReviewGuarantee.State>) {
			self.guarantees = guarantees
		}
	}

	enum ViewAction: Sendable, Equatable {
		case applyTapped
		case closeTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case guarantee(id: TransactionReviewGuarantee.State.ID, action: TransactionReviewGuarantee.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case applyGuarantees(IdentifiedArrayOf<TransactionReviewGuarantee.State>)
	}

	init() {}

	var body: some ReducerOf<TransactionReviewGuarantees> {
		Reduce(core)
			.forEach(\.guarantees, action: /Action.child .. /ChildAction.guarantee) {
				TransactionReviewGuarantee()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
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
struct TransactionReviewGuarantee: Sendable, FeatureReducer {
	struct State: Identifiable, Sendable, Hashable {
		let id: InteractionReview.Transfer.ID
		let account: InteractionReview.ReviewAccount
		let resource: OnLedgerEntity.Resource
		let thumbnail: Thumbnail.FungibleContent
		let amount: Decimal192
		var guarantee: TransactionGuarantee

		var percentageStepper: MinimumPercentageStepper.State

		init?(
			account: InteractionReview.ReviewAccount,
			transfer: InteractionReview.Transfer
		) {
			self.id = transfer.id
			self.account = account
			self.resource = transfer.value.resource

			let url = resource.metadata.iconURL
			switch transfer.details {
			case let .fungible(fungible):
				self.thumbnail = .token(fungible.isXRD ? .xrd : .other(url))
			case .poolUnit:
				self.thumbnail = .poolUnit(url)
			case .liquidStakeUnit:
				self.thumbnail = .lsu(url)
			case .stakeClaimNFT, .nonFungible:
				return nil
			}

			guard let amount = transfer.value.fungibleTransferAmount, amount > 0 else { return nil }
			self.amount = amount

			guard let guarantee = transfer.fungibleGuarantee, guarantee.amount >= 0 else { return nil }
			self.guarantee = guarantee

			self.percentageStepper = .init(value: 100 * guarantee.percentage)

			self.updateAmount()
		}
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case percentageStepper(MinimumPercentageStepper.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.percentageStepper, action: /Action.child .. /ChildAction.percentageStepper) {
			MinimumPercentageStepper()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
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

		let newMinimumDecimal = value * (try! Decimal192(0.01))
		let divisibility: UInt8 = resource.divisibility ?? Decimal192.maxDivisibility
		guarantee.amount = (newMinimumDecimal * amount).rounded(decimalPlaces: divisibility)
		guarantee.percentage = newMinimumDecimal
	}
}
