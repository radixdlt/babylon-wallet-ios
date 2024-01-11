public struct LiquidStakeUnitView: View {
	struct ViewState: Sendable, Hashable {
		public let resource: OnLedgerEntity.Resource
		public let worth: RETDecimal
		public var isSelected: Bool?
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

			HStack {
				TokenBalanceView.xrd(balance: viewState.worth)
					.padding(.small1)
				if let isSelected = viewState.isSelected {
					CheckmarkView(appearance: .dark, isChecked: isSelected)
				}
			}
			.roundedCorners(strokeColor: .app.gray3)
		}
	}
}
