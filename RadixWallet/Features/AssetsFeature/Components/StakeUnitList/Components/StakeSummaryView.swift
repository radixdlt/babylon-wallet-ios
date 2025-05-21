// MARK: - StakeSummaryView
struct StakeSummaryView: View {
	struct ViewState: Hashable, Sendable {
		let staked: Loadable<ExactResourceAmount>
		let unstaking: Loadable<ExactResourceAmount>
		let readyToClaim: Loadable<ExactResourceAmount>
		let canClaimStakes: Bool

		var readyToClaimControlState: ControlState {
			if !canClaimStakes || readyToClaim.isLoading || readyToClaim.wrappedValue?.nominalAmount == .zero {
				.disabled
			} else {
				.enabled
			}
		}
	}

	@Environment(\.resourceBalanceHideFiatValue) var resourceBalanceHideFiatValue
	let viewState: ViewState
	let onReadyToClaimTapped: () -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: .medium3) {
			HStack(spacing: .small2) {
				Image(asset: AssetResource.stakes)
					.resizable()
					.frame(.smallish)
				Text(L10n.Account.Staking.lsuResourceHeader)
					.textStyle(.secondaryHeader)
					.foregroundColor(.primaryText)
			}

			VStack(spacing: .zero) {
				summaryRow(
					L10n.Account.Staking.staked,
					amount: viewState.staked
				)
				.padding(.bottom, viewState.staked.isPositive ? .small3 : .small2)

				summaryRow(
					L10n.Account.Staking.unstaking,
					amount: viewState.unstaking
				)
				.padding(.bottom, viewState.unstaking.isPositive ? .small3 : .small2)

				summaryRow(
					L10n.Account.Staking.readyToClaim,
					amount: viewState.readyToClaim
				)
				.onTapGesture {
					if viewState.readyToClaimControlState == .enabled {
						onReadyToClaimTapped()
					}
				}
			}
			.padding(.leading, .small2)
		}
		.padding(.leading, .medium3)
		.padding(.vertical, .medium2)
		.padding(.trailing, .medium1)
		.background(.primaryBackground)
	}
}

extension StakeSummaryView {
	@ViewBuilder
	private func summaryRow(
		_ name: String,
		amount: Loadable<ExactResourceAmount>
	) -> some View {
		HStack(alignment: .firstTextBaseline) {
			Text(name)
				.textStyle(.body2HighImportance)
				.foregroundColor(.secondaryText)
				.padding(.trailing, .medium3)

			Spacer()

			loadable(amount, loadingViewHeight: .small1) { amount in
				VStack(alignment: .trailing, spacing: .zero) {
					Text("\(amount.nominalAmount.formatted()) XRD")
						.foregroundColor(amount.nominalAmount > 0 ? .primaryText : .tertiaryText)
					if !resourceBalanceHideFiatValue, let fiatWorth = amount.fiatWorth?.currencyFormatted(applyCustomFont: false) {
						Text(fiatWorth)
							.foregroundStyle(.secondaryText)
					}
				}
				.textStyle(.body2HighImportance)
			}
		}
	}
}

private extension Loadable<ExactResourceAmount> {
	var isPositive: Bool {
		if let value = self.nominalAmount.wrappedValue, value > 0 {
			true
		} else {
			false
		}
	}
}
