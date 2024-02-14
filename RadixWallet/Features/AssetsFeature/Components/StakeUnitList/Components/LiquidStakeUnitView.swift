public struct LiquidStakeUnitView: View {
	public struct ViewState: Sendable, Hashable {
		public let resource: OnLedgerEntity.Resource
		public let amount: RETDecimal?
		public let guaranteedAmount: RETDecimal?
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
					Thumbnail(.lsu, url: viewState.resource.metadata.iconURL, size: .extraSmall)
						.padding(.trailing, .small2)

					VStack(alignment: .leading, spacing: .zero) {
						if let title = viewState.resource.metadata.title {
							Text(title)
								.textStyle(.body1Header)
						}

						if let validatorName = viewState.validatorName {
							Text(validatorName)
								.foregroundStyle(.app.gray2)
								.textStyle(.body2Regular)
						}
					}
					.padding(.trailing, .small2)

					Spacer(minLength: 0)

					if let amount = viewState.amount {
						TransactionReviewAmountView(amount: amount, guaranteedAmount: viewState.guaranteedAmount)
							.padding(.leading, viewState.isSelected != nil ? .small2 : 0)
					}

					if let isSelected = viewState.isSelected {
						CheckmarkView(appearance: .dark, isChecked: isSelected)
					}
				}

				VStack(alignment: .leading, spacing: .small3) {
					Text(L10n.Account.Staking.worth.uppercased())
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray2)

					TokenBalanceView.Bordered(viewState: .xrd(balance: viewState.worth))
				}
			}
			.padding(.medium3)
			.background(background)
		}
		.buttonStyle(.borderless)
	}
}
