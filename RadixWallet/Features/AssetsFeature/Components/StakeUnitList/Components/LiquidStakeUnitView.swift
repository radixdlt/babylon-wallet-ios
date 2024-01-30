public struct LiquidStakeUnitView: View {
	public struct ViewState: Sendable, Hashable {
		public let resource: OnLedgerEntity.Resource
		public let worth: RETDecimal
		public var validatorName: String? = nil
		public var isSelected: Bool? = nil
	}

	let viewState: ViewState
	let background: Color
	let onTap: () -> Void

	public var body: some View {
		Button(action: onTap) {
			VStack(alignment: .leading, spacing: .medium3) {
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

				VStack(alignment: .leading, spacing: .small3) {
					Text(L10n.Account.Staking.worth)
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray2)
						.textCase(nil)

					TokenBalanceView.Bordered(viewState: .xrd(balance: viewState.worth))
				}
			}
			.padding(.medium3)
			.background(background)
		}
		.buttonStyle(.borderless)
	}
}
