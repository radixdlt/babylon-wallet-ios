import ComposableArchitecture
import SwiftUI

// MARK: - FungibleResourceAsset
public struct FungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = String
		static let defaultFee: Decimal192 = 1

		public var id: ID {
			resource.resourceAddress.address
		}

		public var balance: Decimal192 {
			resource.amount.nominalAmount
		}

		public var totalExceedsBalance: Bool {
			totalTransferSum > balance
		}

		// Transfered resource
		public let resource: OnLedgerEntity.OwnedFungibleResource
		public let isXRD: Bool

		// MARK: - Mutable state

		@PresentationState
		public var destination: Destination.State? = nil

		public var transferAmountStr: String = ""
		public var transferAmount: Decimal192? = nil

		// Total transfer sum for the transferred resource
		public var totalTransferSum: Decimal192

		public var focused: Bool = false

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

	public enum ViewAction: Equatable, Sendable {
		case amountChanged(String)
		case maxAmountTapped
		case focusChanged(Bool)
		case resourceTapped
	}

	public enum DelegateAction: Equatable, Sendable {
		case amountChanged
		case resourceTapped
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case chooseXRDAmount(AlertState<Action.ChooseXRDAmount>)
			case needsToPayFeeFromOtherAccount(AlertState<Action.NeedsToPayFeeFromOtherAccount>)
		}

		public enum Action: Sendable, Equatable {
			case chooseXRDAmount(ChooseXRDAmount)
			case needsToPayFeeFromOtherAccount(NeedsToPayFeeFromOtherAccount)

			public enum ChooseXRDAmount: Hashable, Sendable {
				case deductFee(Decimal192)
				case sendAll(Decimal192)
				case cancel
			}

			public enum NeedsToPayFeeFromOtherAccount: Hashable, Sendable {
				case confirm(Decimal192)
				case cancel
			}
		}

		public var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
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
