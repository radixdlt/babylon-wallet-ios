// MARK: - StakeSummaryView
public struct StakeSummaryView: View {
	public struct ViewState: Hashable, Sendable {
		public let staked: RETDecimal
		public let unstaking: RETDecimal
		public let readyToClaim: RETDecimal
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
				summaryRow(L10n.Account.Staking.staked, amount: viewState.staked)
				summaryRow(L10n.Account.Staking.unstaking, amount: viewState.unstaking)
				summaryRow(L10n.Account.Staking.readyToClaim, amount: viewState.readyToClaim)
			}
		}
	}
}

extension StakeSummaryView {
	@ViewBuilder
	private func summaryRow(_ name: String, amount: RETDecimal) -> some View {
		HStack {
			Text(name)
				.textStyle(.body2HighImportance)
				.foregroundColor(.app.gray2)
				.padding(.trailing, .medium3)
			Spacer()
			Text("\(amount.formatted()) XRD")
				.textStyle(.body2HighImportance)
				.foregroundColor(amount.isZero() ? .app.gray2 : .app.gray1)
		}
	}
}
