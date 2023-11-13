import ComposableArchitecture
import SwiftUI

// MARK: - FeesView
struct FeesView: View {
	struct ViewState: Equatable, Sendable {
		let feeViewStates: IdentifiedArrayOf<FeeViewState>
		let totalFee: RETDecimal
		let isAdvancedMode: Bool
	}

	let viewState: ViewState

	var body: some View {
		VStack(spacing: .small1) {
			HStack {
				Text(L10n.CustomizeNetworkFees.feeBreakdownTitle)
					.textStyle(.body1Link)
					.foregroundColor(.app.gray2)
					.textCase(.uppercase)
				Spacer()
			}
			.padding(.horizontal, .medium1)

			VStack(spacing: .small1) {
				ForEach(viewState.feeViewStates) { viewState in
					feeView(state: viewState)
				}

				Divider()

				transactionFeeView(fee: viewState.totalFee.formatted(), isAdvancedMode: viewState.isAdvancedMode)
			}
			.padding(.medium1)
			.background(.app.gray5)
		}
	}

	@ViewBuilder
	func transactionFeeView(fee: String, isAdvancedMode: Bool) -> some SwiftUI.View {
		HStack {
			VStack(spacing: .zero) {
				Text(L10n.CustomizeNetworkFees.totalFee)
					.textStyle(.body1Link)
					.foregroundColor(.app.gray2)
					.textCase(.uppercase)
				if isAdvancedMode {
					Text(L10n.CustomizeNetworkFees.TotalFee.info)
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
				}
			}
			Spacer()
			Text(L10n.TransactionReview.xrdAmount(fee))
				.textStyle(.body1Header)
				.foregroundColor(.app.gray1)
		}
	}

	@ViewBuilder
	func feeView(state: FeeViewState) -> some SwiftUI.View {
		HStack {
			Text(state.name)
				.textStyle(.body1Link)
				.foregroundColor(.app.gray2)
				.textCase(.uppercase)
			Spacer()
			Text(state.amount.formatted(showsZero: state.isUserConfigurable))
				.textStyle(.body1HighImportance)
				.foregroundColor(state.amount == .zero ? .app.gray2 : .app.gray1)
		}
	}
}

// MARK: - FeeViewState
struct FeeViewState: Equatable, Sendable, Identifiable {
	var id: String { name }

	let name: String
	let amount: RETDecimal
	let isUserConfigurable: Bool
	init(name: String, amount: RETDecimal, isUserConfigurable: Bool = false) {
		self.name = name
		self.amount = amount
		self.isUserConfigurable = isUserConfigurable
	}
}

extension TransactionFee.AdvancedFeeCustomization {
	var viewStates: IdentifiedArrayOf<FeeViewState> {
		var displayedFees = IdentifiedArrayOf<FeeViewState>(uncheckedUniqueElements: [
			.init(
				name: L10n.CustomizeNetworkFees.networkExecution,
				amount: feeSummary.totalExecutionCost
			),
			.init(
				name: L10n.CustomizeNetworkFees.networkFinalization,
				amount: feeSummary.finalizationCost
			),
			.init(
				name: L10n.CustomizeNetworkFees.effectiveTip,
				amount: tipAmount,
				isUserConfigurable: true
			),
			.init(
				name: L10n.CustomizeNetworkFees.networkStorage,
				amount: feeSummary.storageExpansionCost
			),
			.init(
				name: L10n.CustomizeNetworkFees.padding,
				amount: paddingFee,
				isUserConfigurable: true
			),
			.init(
				name: L10n.CustomizeNetworkFees.royalties,
				amount: feeSummary.royaltyCost
			),
		])

		if paidByDapps > .zero {
			displayedFees.append(
				.init(
					name: L10n.CustomizeNetworkFees.paidByDApps,
					amount: paidByDapps
				)
			)
		}
		return displayedFees
	}
}

extension TransactionFee.NormalFeeCustomization {
	var viewStates: IdentifiedArrayOf<FeeViewState> {
		.init(uncheckedUniqueElements: [
			.init(
				name: L10n.CustomizeNetworkFees.networkFee,
				amount: networkFee
			),
			.init(
				name: L10n.CustomizeNetworkFees.royaltyFee,
				amount: royaltyFee
			),
		])
	}
}

extension RETDecimal {
	func formatted(showsZero: Bool) -> String {
		if !showsZero, isZero() {
			return L10n.CustomizeNetworkFees.noneDue
		}
		return L10n.TransactionReview.xrdAmount(formatted())
	}
}
