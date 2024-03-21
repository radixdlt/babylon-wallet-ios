// MARK: - StakeSummaryView
public struct StakeSummaryView: View {
	public struct ViewState: Hashable, Sendable {
		public let staked: Loadable<ResourceAmount>
		public let unstaking: Loadable<ResourceAmount>
		public let readyToClaim: Loadable<ResourceAmount>
		public let canClaimStakes: Bool

		public var readyToClaimControlState: ControlState {
			if !canClaimStakes || readyToClaim.isLoading || readyToClaim.wrappedValue?.nominalAmount == .zero() {
				.disabled
			} else {
				.enabled
			}
		}
	}

	public let viewState: ViewState
	public let onReadyToClaimTapped: () -> Void

	public var body: some View {
		VStack(spacing: .medium1) {
			HStack {
				Image(asset: AssetResource.stakes)
				Text(L10n.Account.Staking.lsuResourceHeader)
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray1)
				Spacer()
			}
			.padding(.leading, -8)

			VStack(spacing: .small2) {
				summaryRow(
					L10n.Account.Staking.staked,
					amount: viewState.staked,
					amountTextColor: .app.gray1
				)

				summaryRow(
					L10n.Account.Staking.unstaking,
					amount: viewState.unstaking
				)

				summaryRow(
					L10n.Account.Staking.readyToClaim,
					amount: viewState.readyToClaim,
					titleTextColor: viewState.readyToClaimControlState == .enabled ? .app.blue1 : .app.gray2
				)
				.onTapGesture {
					if viewState.readyToClaimControlState == .enabled {
						onReadyToClaimTapped()
					}
				}
			}
		}
	}
}

extension StakeSummaryView {
	@ViewBuilder
	private func summaryRow(
		_ name: String,
		amount: Loadable<ResourceAmount>,
		titleTextColor: Color = .app.gray2,
		amountTextColor: Color = .app.gray2
	) -> some View {
		HStack(alignment: .firstTextBaseline) {
			Text(name)
				.textStyle(.body2HighImportance)
				.foregroundColor(titleTextColor)
				.padding(.trailing, .medium3)

			Spacer()

			loadable(amount, loadingViewHeight: .small1) { amount in
				VStack(alignment: .trailing) {
					Text("\(amount.nominalAmount.formatted()) XRD")
						.textStyle(.body2HighImportance)
						.foregroundColor(amountTextColor)
					if let fiatWorth = amount.fiatWorth?.currencyFormatted(applyCustomFont: false) {
						Text(fiatWorth)
							.textStyle(.body2HighImportance)
							.foregroundStyle(.app.gray2)
					}
				}
			}
		}
	}
}
