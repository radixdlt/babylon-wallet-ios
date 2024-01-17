// MARK: - TransferPoolUnitView
public struct TransferPoolUnitView: View {
	public struct ViewState: Equatable {
		public let poolName: String
		public let resources: [TransferPoolUnitResourceView.ViewState]
	}

	public let viewState: ViewState
	public let onTap: () -> Void

	public var body: some View {
		Button(action: onTap) {
			VStack(alignment: .leading, spacing: .zero) {
				HStack(spacing: .small2) {
					ZStack {
						Circle()
							.fill(.app.gray4)
							.frame(width: .large1, height: .large1)

						AssetIcon(.asset(AssetResource.poolUnits), size: .verySmall)
					}

					VStack(alignment: .leading, spacing: 0) {
						Text(L10n.TransactionReview.poolUnits)
							.textStyle(.body1Header)
							.foregroundColor(.app.gray1)

						Text(viewState.poolName)
							.textStyle(.body2Regular)
							.foregroundColor(.app.gray2)
					}

					Spacer(minLength: 0)

//					AssetIcon(.asset(AssetResource.info), size: .smallest)
//						.tint(.app.gray3)
				}
				.padding(.bottom, .small2)

				Text(L10n.TransactionReview.worth)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)
					.padding(.bottom, .small3)

				TransferPoolUnitResourcesView(resources: viewState.resources)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.medium3)
		.background(.app.gray5)
	}
}

// MARK: - TransferPoolUnitResourcesView
public struct TransferPoolUnitResourcesView: View {
	public let resources: [TransferPoolUnitResourceView.ViewState]

	public var body: some View {
		VStack(spacing: 1) {
			ForEach(resources) { resource in
				TransferPoolUnitResourceView(viewState: resource)
			}
			.padding(.small1)
			.background(.app.gray5)
		}
		.background(.app.gray3)
		.overlay(
			RoundedRectangle(cornerRadius: .small2)
				.stroke(.app.gray3, lineWidth: 1)
		)
	}
}

// MARK: - TransferPoolUnitResourceView
public struct TransferPoolUnitResourceView: View {
	public struct ViewState: Identifiable, Equatable {
		public var id: ResourceAddress
		public let symbol: String?
		public let icon: TokenThumbnail.Content
		public let amount: RETDecimal
	}

	public let viewState: ViewState

	public var body: some View {
		HStack(spacing: .zero) {
			TokenThumbnail(viewState.icon, size: .smallest)
				.padding(.trailing, .small1)

			if let symbol = viewState.symbol {
				Text(symbol)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray1)
			}

			Spacer(minLength: .small2)

			Text(viewState.amount.formattedPlain())
				.lineLimit(1)
				.minimumScaleFactor(0.8)
				.truncationMode(.tail)
				.textStyle(.secondaryHeader)
				.foregroundColor(.app.gray1)
		}
	}
}
