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
			VStack(alignment: .leading, spacing: .zero) {
				HStack(spacing: .zero) {
					TokenThumbnail(.known(viewState.resource.metadata.iconURL), size: .smaller)
						.padding(.trailing, .small2)

					VStack(alignment: .leading, spacing: .zero) {
						Text(viewState.resource.metadata.name ?? L10n.Account.PoolUnits.unknownPoolUnitName)
							.textStyle(.body1Header)

						if let validatorName = viewState.validatorName {
							Text(validatorName)
								.foregroundStyle(.app.gray2)
								.textStyle(.body2Regular)
						}
					}
					.padding(.trailing, .small2)

					Spacer(minLength: 0)

					if let isSelected = viewState.isSelected {
						CheckmarkView(appearance: .dark, isChecked: isSelected)
					}
				}
				.padding(.bottom, .medium3)

				Text(L10n.Account.Staking.worth)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)
					.textCase(nil)
					.padding(.bottom, .small3)

				TokenBalanceView.xrd(balance: viewState.worth)
					.padding(.small1)
					.roundedCorners(strokeColor: .app.gray3)
			}
		}
		.buttonStyle(.borderless)
	}
}
