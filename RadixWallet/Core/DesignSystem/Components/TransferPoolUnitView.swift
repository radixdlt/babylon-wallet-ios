// MARK: - TransferPoolUnitView
public struct TransferPoolUnitView: View {
	public struct ViewState: Equatable {
		public let poolName: String?
		public let dAppName: String?
		public let poolIcon: URL?
		public let resources: Loadable<[TransferPoolUnitResourceView.ViewState]>
		public let isSelected: Bool?
	}

	public let viewState: ViewState
	public let backgroundColor: Color
	public let onTap: () -> Void

	public var body: some View {
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

					if let dAppName = viewState.dAppName {
						Text(dAppName)
							.textStyle(.body2Regular)
							.foregroundColor(.app.gray2)
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
					TransferPoolUnitResourcesView(resources: resources, resourceBackgroundColor: backgroundColor)
						.padding(.trailing, .small2)

					if let isSelected = viewState.isSelected {
						CheckmarkView(appearance: .dark, isChecked: isSelected)
					}
				}
			}
		}
		.background(backgroundColor)
		.padding(.medium1)
		.contentShape(Rectangle())
		.onTapGesture {
			onTap()
		}
	}
}

// MARK: - TransferPoolUnitResourcesView
public struct TransferPoolUnitResourcesView: View {
	public let resources: [TransferPoolUnitResourceView.ViewState]
	public let resourceBackgroundColor: Color

	public var body: some View {
		VStack(spacing: 1) {
			ForEach(resources) { resource in
				TransferPoolUnitResourceView(viewState: resource)
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

// MARK: - TransferPoolUnitResourceView
public struct TransferPoolUnitResourceView: View {
	public struct ViewState: Identifiable, Equatable {
		public var id: ResourceAddress
		public let symbol: String?
		public let icon: TokenThumbnail.Content
		public let amount: String
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
