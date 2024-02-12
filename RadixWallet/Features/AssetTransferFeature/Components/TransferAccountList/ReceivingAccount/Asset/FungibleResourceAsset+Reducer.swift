import ComposableArchitecture
import SwiftUI

// MARK: - FungibleResourceAsset
public struct FungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = String
		static let defaultFee: RETDecimal = 1

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
		public var alert: AlertState<ViewAction.Alert>?

		public var transferAmountStr: String = ""
		public var transferAmount: RETDecimal? = nil

		// Total transfer sum for the transferred resource
		public var totalTransferSum: RETDecimal

		public var focused: Bool = false

		init(
			resource: OnLedgerEntity.OwnedFungibleResource,
			isXRD: Bool,
			totalTransferSum: RETDecimal = .zero
		) {
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

		case alert(PresentationAction<Alert>)

		public enum Alert: Hashable, Sendable {
			case chooseXRDAmountAlert(ChooseXRDAmountAlert)
			case needsToPayFeeFromOtherAccount(NeedsToPayFeeFromOtherAccount)

			public enum ChooseXRDAmountAlert: Hashable, Sendable {
				case deductFee(RETDecimal)
				case sendAll(RETDecimal)
				case cancel
			}

			public enum NeedsToPayFeeFromOtherAccount: Hashable, Sendable {
				case confirm(RETDecimal)
				case cancel
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
				if remainingAmount >= State.defaultFee {
					state.alert = .chooseXRDAmount(
						feeDeductedAmount: remainingAmount - State.defaultFee,
						maxAmount: remainingAmount
					)
					return .none
				} else if remainingAmount > 0 {
					state.alert = .willNeedToPayFeeFromOtherAccount(remainingAmount)
					return .none
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

		case let .alert(action):
			state.alert = nil
			switch action {
			case let .presented(.chooseXRDAmountAlert(.deductFee(amount))),
			     let .presented(.chooseXRDAmountAlert(.sendAll(amount))),
			     let .presented(.needsToPayFeeFromOtherAccount(.confirm(amount))):
				state.transferAmount = amount
				state.transferAmountStr = amount.formattedPlain(useGroupingSeparator: false)
				return .send(.delegate(.amountChanged))

			case .presented(.needsToPayFeeFromOtherAccount(.cancel)),
			     .presented(.chooseXRDAmountAlert(.cancel)):
				return .none

			case .dismiss:
				return .none
			}
		}
	}
}

extension AlertState where Action == FungibleResourceAsset.ViewAction.Alert {
	fileprivate static func chooseXRDAmount(feeDeductedAmount: RETDecimal, maxAmount: RETDecimal) -> Self {
		AlertState(
			title: TextState(L10n.AssetTransfer.MaxAmountDialog.title),
			message: TextState(L10n.AssetTransfer.MaxAmountDialog.body),
			buttons:
			[
				ButtonState.default(
					TextState(L10n.AssetTransfer.MaxAmountDialog.saveXrdForFeeButton(feeDeductedAmount.formatted())),
					action: .send(.chooseXRDAmountAlert(.deductFee(feeDeductedAmount)))
				),
				ButtonState.default(
					TextState(L10n.AssetTransfer.MaxAmountDialog.sendAllButton(maxAmount.formatted())),
					action: .send(.chooseXRDAmountAlert(.sendAll(maxAmount)))
				),
				ButtonState.default(
					TextState(L10n.Common.cancel),
					action: .send(.chooseXRDAmountAlert(.cancel))
				),
			]
		)
	}

	fileprivate static func willNeedToPayFeeFromOtherAccount(_ amount: RETDecimal) -> Self {
		AlertState(
			title: TextState(L10n.AssetTransfer.MaxAmountDialog.title),
			message: TextState("Sending the full amount of XRD in this account will require you to pay the transaction fee from a different account"),
			buttons:
			[
				ButtonState.default(
					TextState(L10n.Common.ok),
					action: .send(.needsToPayFeeFromOtherAccount(.confirm(amount)))
				),
				ButtonState.default(
					TextState(L10n.Common.cancel),
					action: .send(.needsToPayFeeFromOtherAccount(.cancel))
				),
			]
		)
	}
}
