// MARK: - PoolUnitView
public struct PoolUnitView: View {
	public struct ViewState: Equatable {
		public let poolName: String?
		public let amount: RETDecimal?
		public let guaranteedAmount: RETDecimal?
		public let dAppName: Loadable<String?>
		public let poolIcon: URL?
		public let resources: Loadable<[ResourceBalance.Fungible]>
		public let isSelected: Bool?
	}

	public let viewState: ViewState
	public let background: Color
	public let onTap: () -> Void

	public var body: some View {
		Button(action: onTap) {
			VStack(alignment: .leading, spacing: .zero) {
				HStack(spacing: .zero) {
					Thumbnail(.poolUnit, url: viewState.poolIcon, size: .slightlySmaller)
						.padding(.trailing, .small1)

					VStack(alignment: .leading, spacing: 0) {
						Text(viewState.poolName ?? L10n.TransactionReview.poolUnits)
							.textStyle(.body1Header)
							.foregroundColor(.app.gray1)

						loadable(viewState.dAppName, loadingViewHeight: .small1) { dAppName in
							if let dAppName {
								Text(dAppName)
									.textStyle(.body2Regular)
									.foregroundColor(.app.gray2)
							}
						}
					}

					Spacer(minLength: 0)

					if let amount = viewState.amount {
						TransactionReviewAmountView(amount: amount, guaranteedAmount: viewState.guaranteedAmount)
							.padding(.leading, viewState.isSelected != nil ? .small2 : 0)
					}

					if let isSelected = viewState.isSelected {
						CheckmarkView(appearance: .dark, isChecked: isSelected)
					}

					//					AssetIcon(.asset(AssetResource.info), size: .smallest)
					//						.tint(.app.gray3)
				}
				.padding(.bottom, .small2)

				Text(L10n.TransactionReview.worth.uppercased())
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)
					.padding(.bottom, .small3)

				loadable(viewState.resources) { fungibles in
					ResourceBalancesView(fungibles: fungibles)
				}
			}
			.padding(.medium3)
			.background(background)
		}
		.buttonStyle(.borderless)
	}
}
