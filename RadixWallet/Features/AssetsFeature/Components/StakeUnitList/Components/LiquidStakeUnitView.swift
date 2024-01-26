public struct LiquidStakeUnitView: View {
	public struct ViewState: Sendable, Hashable {
		public let resource: OnLedgerEntity.Resource
		public let worth: RETDecimal
		public var validatorName: String? = nil
		public var isSelected: Bool? = nil
	}

	let viewState: ViewState
	let action: () -> Void

	public var body: some View {
		Button(action: action) {
			VStack(alignment: .leading, spacing: .small2) {
				HStack {
					TokenThumbnail(.known(viewState.resource.metadata.iconURL), size: .smaller)

					VStack(alignment: .leading, spacing: .zero) {
						Text(viewState.resource.metadata.name ?? L10n.Account.PoolUnits.unknownPoolUnitName)
							.textStyle(.body1Header)

						if let validatorName = viewState.validatorName {
							Text(validatorName)
								.foregroundStyle(.app.gray2)
								.textStyle(.body2Regular)
						}
					}

					Spacer()
				}

				Text(L10n.Account.Staking.worth)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)
					.textCase(nil)

				HStack {
					TokenBalanceView.xrd(balance: viewState.worth)
					if let isSelected = viewState.isSelected {
						CheckmarkView(appearance: .dark, isChecked: isSelected)
					}
				}
				.padding(.small1)
				.background(.white)
				.roundedCorners(strokeColor: .app.gray3)
			}
		}
	}
}
