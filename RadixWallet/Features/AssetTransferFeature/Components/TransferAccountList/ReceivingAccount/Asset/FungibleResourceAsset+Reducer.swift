import ComposableArchitecture
import SwiftUI

// MARK: - FungibleResourceAsset
struct FungibleResourceAsset: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		typealias ID = String
		static let defaultFee: Decimal192 = 1

		var id: ID {
			resource.resourceAddress.address
		}

		var balance: Decimal192 {
			resource.amount.exactAmount!.nominalAmount
		}

		var totalExceedsBalance: Bool {
			totalTransferSum > balance
		}

		// Transfered resource
		let resource: OnLedgerEntity.OwnedFungibleResource
		let isXRD: Bool

		// MARK: - Mutable state

		@PresentationState
		var destination: Destination.State? = nil

		var transferAmountStr: String = ""
		var transferAmount: Decimal192? = nil

		// Total transfer sum for the transferred resource
		var totalTransferSum: Decimal192

		var focused: Bool = false

		init(
			resource: OnLedgerEntity.OwnedFungibleResource,
			isXRD: Bool,
			totalTransferSum: Decimal192 = .zero
		) {
			self.resource = resource
			self.isXRD = isXRD
			self.totalTransferSum = totalTransferSum
		}
	}

	enum ViewAction: Equatable, Sendable {
		case amountChanged(String)
		case maxAmountTapped
		case focusChanged(Bool)
		case resourceTapped
	}

	enum DelegateAction: Equatable, Sendable {
		case amountChanged
		case resourceTapped
	}

	struct Destination: DestinationReducer {
		enum State: Sendable, Hashable {
			case chooseXRDAmount(AlertState<Action.ChooseXRDAmount>)
			case needsToPayFeeFromOtherAccount(AlertState<Action.NeedsToPayFeeFromOtherAccount>)
		}

		enum Action: Sendable, Equatable {
			case chooseXRDAmount(ChooseXRDAmount)
			case needsToPayFeeFromOtherAccount(NeedsToPayFeeFromOtherAccount)

			enum ChooseXRDAmount: Hashable, Sendable {
				case deductFee(Decimal192)
				case sendAll(Decimal192)
				case cancel
			}

			enum NeedsToPayFeeFromOtherAccount: Hashable, Sendable {
				case confirm(Decimal192)
				case cancel
			}
		}

		var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .amountChanged(transferAmountStr):
			state.transferAmountStr = transferAmountStr

			if let value = try? Decimal192(formattedString: transferAmountStr), !value.isNegative {
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
					state.destination = .chooseXRDAmount(.alert(
						feeDeductedAmount: remainingAmount - State.defaultFee,
						maxAmount: remainingAmount
					))
					return .none
				} else if remainingAmount > 0 {
					state.destination = .needsToPayFeeFromOtherAccount(.anotherAccount(remainingAmount))
					return .none
				}
			}

			state.transferAmount = remainingAmount
			state.transferAmountStr = remainingAmount.formattedPlain(useGroupingSeparator: false)
			return .send(.delegate(.amountChanged))

		case let .focusChanged(focused):
			state.focused = focused
			return .none

		case .resourceTapped:
			return .send(.delegate(.resourceTapped))
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .chooseXRDAmount(.deductFee(amount)),
		     let .chooseXRDAmount(.sendAll(amount)),
		     let .needsToPayFeeFromOtherAccount(.confirm(amount)):
			state.transferAmount = amount
			state.transferAmountStr = amount.formattedPlain(useGroupingSeparator: false)
			return .send(.delegate(.amountChanged))

		default:
			return .none
		}
	}
}

extension AlertState<FungibleResourceAsset.Destination.Action.ChooseXRDAmount> {
	fileprivate static func alert(feeDeductedAmount: Decimal192, maxAmount: Decimal192) -> AlertState {
		AlertState {
			TextState(L10n.AssetTransfer.MaxAmountDialog.title)
		} actions: {
			ButtonState(action: .deductFee(feeDeductedAmount)) {
				TextState(L10n.AssetTransfer.MaxAmountDialog.saveXrdForFeeButton(feeDeductedAmount.formatted()))
			}
			ButtonState(action: .sendAll(maxAmount)) {
				TextState(L10n.AssetTransfer.MaxAmountDialog.sendAllButton(maxAmount.formatted()))
			}
			ButtonState(role: .cancel, action: .cancel) {
				TextState(L10n.Common.cancel)
			}
		} message: {
			TextState(L10n.AssetTransfer.MaxAmountDialog.body)
		}
	}
}

extension AlertState<FungibleResourceAsset.Destination.Action.NeedsToPayFeeFromOtherAccount> {
	fileprivate static func anotherAccount(_ amount: Decimal192) -> AlertState {
		AlertState {
			TextState(L10n.AssetTransfer.MaxAmountDialog.title)
		} actions: {
			ButtonState(action: .confirm(amount)) {
				TextState(L10n.Common.ok)
			}
			ButtonState(role: .cancel, action: .cancel) {
				TextState(L10n.Common.cancel)
			}
		} message: {
			TextState("Sending the full amount of XRD in this account will require you to pay the transaction fee from a different account")
		}
	}
}
