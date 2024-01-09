public struct LiquidStakeUnitView: View {
	struct ViewState: Sendable, Hashable {
		public let resource: OnLedgerEntity.Resource
		public let worth: RETDecimal
	}

	let viewState: ViewState

	public var body: some View {
		VStack(alignment: .leading, spacing: .small2) {
			HStack {
				TokenThumbnail(.known(viewState.resource.metadata.iconURL), size: .smaller)
				Text(viewState.resource.metadata.name ?? L10n.Account.PoolUnits.unknownPoolUnitName)
					.textStyle(.body1Header)

				Spacer()
			}

			Text(L10n.Account.Staking.worth)
				.textStyle(.body2HighImportance)
				.foregroundColor(.app.gray2)
				.textCase(nil)

			TokenBalanceView.xrd(balance: viewState.worth)
				.padding(.small1)
				.roundedCorners(strokeColor: .app.gray3)
		}
	}
}
