import ComposableArchitecture
import SwiftUI

// MARK: - FungibleResourceAsset
public struct FungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = String

		public var id: ID {
			resource.resourceAddress.address
		}

		public var balance: RETDecimal {
			resource.amount
		}

		public var totalExceedsBalance: Bool {
			totalTransferSum > balance
		}

		// Transfered resource
		public let resource: OnLedgerEntity.OwnedFungibleResource
		public let isXRD: Bool

		// MARK: - Mutable state

		@PresentationState
		public var alert: AlertState<ViewAction.AlertAction>?

		public var transferAmountStr: String = ""
		public var transferAmount: RETDecimal? = nil

		// Total transfer sum for the transferred resource
		public var totalTransferSum: RETDecimal

		public var focused: Bool = false

		init(resource: OnLedgerEntity.OwnedFungibleResource, isXRD: Bool, totalTransferSum: RETDecimal = .zero) {
			self.resource = resource
			self.isXRD = isXRD
			self.totalTransferSum = totalTransferSum
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case amountChanged(String)
		case maxAmountTapped
		case focusChanged(Bool)
		case removeTapped

		case alertAction(PresentationAction<AlertAction>)

		public enum AlertAction: Hashable, Sendable {
			case chooseXRDAmountAlert(ChooseXRDAmountAlert)
			case needsToPayFeeFromOtherAccount(EqVoid)

			public enum ChooseXRDAmountAlert: Hashable, Sendable {
				case deductFee(RETDecimal)
				case sendAll(RETDecimal)
			}
		}
	}

	public enum DelegateAction: Equatable, Sendable {
		case removed
		case amountChanged
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .amountChanged(transferAmountStr):
			state.transferAmountStr = transferAmountStr

			if let value = try? RETDecimal(formattedString: transferAmountStr), !value.isNegative() {
				state.transferAmount = value
			} else {
				state.transferAmount = nil
			}
			return .send(.delegate(.amountChanged))

		case .maxAmountTapped:
			let sumOfOthers = state.totalTransferSum - (state.transferAmount ?? .zero)
			let remainingAmount = (state.balance - sumOfOthers).clamped

			if state.isXRD {
				if remainingAmount >= 1 {
					state.alert = .chooseXRDAmount(
						feeDeductedAmount: remainingAmount - 1,
						maxAmount: remainingAmount
					)
					return .none
				} else {
					state.alert = .willNeedToPayFeeFromOtherAccount()
				}
			}

			state.transferAmount = remainingAmount
			state.transferAmountStr = remainingAmount.formattedPlain(useGroupingSeparator: false)
			return .send(.delegate(.amountChanged))

		case let .focusChanged(focused):
			state.focused = focused
			return .none

		case .removeTapped:
			return .send(.delegate(.removed))

		case let .alertAction(action):
			state.alert = nil
			switch action {
			case let .presented(.chooseXRDAmountAlert(.deductFee(amount))),
			     let .presented(.chooseXRDAmountAlert(.sendAll(amount))):
				state.transferAmount = amount
				state.transferAmountStr = amount.formattedPlain(useGroupingSeparator: false)
				return .send(.delegate(.amountChanged))
			case .presented(.needsToPayFeeFromOtherAccount):
				return .none
			case .dismiss:
				return .none
			}
		}
	}
}

extension AlertState where Action == FungibleResourceAsset.ViewAction.AlertAction {
	fileprivate static func chooseXRDAmount(feeDeductedAmount: RETDecimal, maxAmount: RETDecimal) -> Self {
		.init(
			title: .init(L10n.AssetTransfer.MaxAmountDialog.title),
			message: .init(L10n.AssetTransfer.MaxAmountDialog.body),
			buttons:
			[
				.default(
					.init(L10n.AssetTransfer.MaxAmountDialog.saveXrdForFeeButton(feeDeductedAmount.formatted())),
					action: .send(.chooseXRDAmountAlert(.deductFee(feeDeductedAmount)))
				),
				.default(
					.init(L10n.AssetTransfer.MaxAmountDialog.sendAllButton(maxAmount.formatted())),
					action: .send(.chooseXRDAmountAlert(.sendAll(maxAmount)))
				),
			]
		)
	}

	fileprivate static func willNeedToPayFeeFromOtherAccount() -> Self {
		.init(
			title: .init(L10n.AssetTransfer.MaxAmountDialog.title),
			message: .init("Sending the full amount of XRD in this account will require you to pay the transaction fee from a different account")
		)
	}
}
