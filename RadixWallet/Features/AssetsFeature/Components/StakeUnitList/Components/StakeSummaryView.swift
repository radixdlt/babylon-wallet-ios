// MARK: - StakeSummaryView
public struct StakeSummaryView: View {
	public struct ViewState: Hashable, Sendable {
		public let staked: Loadable<ResourceAmount>
		public let unstaking: Loadable<ResourceAmount>
		public let readyToClaim: Loadable<ResourceAmount>
		public let canClaimStakes: Bool

		public var readyToClaimControlState: ControlState {
			if !canClaimStakes || readyToClaim.isLoading || readyToClaim.wrappedValue?.nominalAmount == .zero {
				.disabled
			} else {
				.enabled
			}
		}
	}

	@Environment(\.resourceBalanceHideFiatValue) var resourceBalanceHideFiatValue
	public let viewState: ViewState
	public let onReadyToClaimTapped: () -> Void

	public var body: some View {
		VStack(alignment: .leading, spacing: .medium3) {
			HStack(spacing: .small2) {
				Image(asset: AssetResource.stakes)
					.resizable()
					.frame(.smallish)
				Text(L10n.Account.Staking.lsuResourceHeader)
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray1)
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
	}
}

extension StakeSummaryView {
	@ViewBuilder
	private func summaryRow(
		_ name: String,
		amount: Loadable<ResourceAmount>
	) -> some View {
		HStack(alignment: .firstTextBaseline) {
			Text(name)
				.textStyle(.body2HighImportance)
				.foregroundColor(.app.gray2)
				.padding(.trailing, .medium3)

			Spacer()

			loadable(amount, loadingViewHeight: .small1) { amount in
				VStack(alignment: .trailing, spacing: .zero) {
					Text("\(amount.nominalAmount.formatted()) XRD")
						.foregroundColor(amount.nominalAmount > 0 ? .app.gray1 : .app.gray3)
					if !resourceBalanceHideFiatValue, let fiatWorth = amount.fiatWorth?.currencyFormatted(applyCustomFont: false) {
						Text(fiatWorth)
							.foregroundStyle(.app.gray2)
					}
				}
				.textStyle(.body2HighImportance)
			}
		}
	}
}

private extension Loadable<ResourceAmount> {
	var isPositive: Bool {
		guard let value = self.nominalAmount.wrappedValue else {
			return false
		}
		return value > 0
	}
}
