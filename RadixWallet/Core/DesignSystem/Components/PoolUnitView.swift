// MARK: - PoolUnitView
public struct PoolUnitView: View {
	public struct ViewState: Equatable {
		public let poolName: String?
		public let dAppName: Loadable<String?>
		public let poolIcon: URL?
		public let resources: Loadable<[PoolUnitResourceView.ViewState]>
		public let isSelected: Bool?
	}

	public let viewState: ViewState
	public let backgroundColor: Color
	public let onTap: () -> Void

	public var body: some View {
		Button(action: onTap) {
			VStack(alignment: .leading, spacing: .zero) {
				HStack(spacing: .zero) {
					LoadableImage(url: viewState.poolIcon, size: .fixedSize(.verySmall)) {
						ZStack {
							Circle()
								.fill(.app.gray4)
								.frame(width: .large1, height: .large1)
							Image(asset: AssetResource.poolUnits)
								.resizable()
								.frame(.verySmall)
						}
					}
					.padding(.trailing, .medium3)

					VStack(alignment: .leading, spacing: 0) {
						if let poolName = viewState.poolName {
							Text(poolName)
								.textStyle(.body1Header)
								.foregroundColor(.app.gray1)
						}

						loadable(viewState.dAppName, loadingViewHeight: .small1) { dAppName in
							if let dAppName {
								Text(dAppName)
									.textStyle(.body2Regular)
									.foregroundColor(.app.gray2)
							}
						}
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

				loadable(viewState.resources) { resources in
					HStack(spacing: .zero) {
						PoolUnitResourcesView(resources: resources, resourceBackgroundColor: backgroundColor)
							.padding(.trailing, .small2)

						if let isSelected = viewState.isSelected {
							CheckmarkView(appearance: .dark, isChecked: isSelected)
						}
					}
				}
			}
			.background(backgroundColor)
			.padding(.medium1)
		}
		// .contentShape(Rectangle())
//		.onTapGesture {
//
//		}
	}
}

// MARK: - PoolUnitResourcesView
public struct PoolUnitResourcesView: View {
	public let resources: [PoolUnitResourceView.ViewState]
	public let resourceBackgroundColor: Color

	public var body: some View {
		VStack(spacing: 1) {
			ForEach(resources) { resource in
				PoolUnitResourceView(viewState: resource)
			}
			.padding(.small1)
			.background(resourceBackgroundColor)
		}
		.background(.app.gray3)
		.overlay(
			RoundedRectangle(cornerRadius: .small2)
				.stroke(.app.gray3, lineWidth: 1)
		)
	}
}

// MARK: - PoolUnitResourceView
public struct PoolUnitResourceView: View {
	public struct ViewState: Identifiable, Equatable {
		public var id: ResourceAddress
		public let symbol: String?
		public let icon: TokenThumbnail.Content
		public let amount: String

		public init(
			id: ResourceAddress,
			symbol: String?,
			icon: TokenThumbnail.Content,
			amount: String
		) {
			self.id = id
			self.symbol = symbol
			self.icon = icon
			self.amount = amount
		}

		public init(
			id: ResourceAddress,
			symbol: String?,
			icon: TokenThumbnail.Content,
			amount: RETDecimal?
		) {
			self.id = id
			self.symbol = symbol
			self.icon = icon
			self.amount = amount.map { $0.formatted() } ?? L10n.Account.PoolUnits.noTotalSupply
		}
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

			Text(viewState.amount)
				.lineLimit(1)
				.minimumScaleFactor(0.8)
				.truncationMode(.tail)
				.textStyle(.secondaryHeader)
				.foregroundColor(.app.gray1)
		}
	}
}
