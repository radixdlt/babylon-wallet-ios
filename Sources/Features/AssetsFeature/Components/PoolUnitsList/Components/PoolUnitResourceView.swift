import FeaturePrelude

// MARK: - PoolUnitResourceViewState
struct PoolUnitResourceViewState: Identifiable, Equatable {
	var id: String {
		symbol
	}

	let thumbnail: TokenThumbnail.Content
	let symbol: String
	let tokenAmount: String
	let isSelected: Bool?

	init(
		thumbnail: TokenThumbnail.Content,
		symbol: String,
		tokenAmount: String,
		isSelected: Bool? = nil
	) {
		self.thumbnail = thumbnail
		self.symbol = symbol
		self.tokenAmount = tokenAmount
		self.isSelected = isSelected
	}
}

extension PoolUnitResourceViewState {
	init(xrdAmount: String, isSelected: Bool?) {
		self.init(
			thumbnail: .xrd,
			symbol: "XRD",
			tokenAmount: xrdAmount,
			isSelected: isSelected
		)
	}
}

// MARK: - PoolUnitResourceView
struct PoolUnitResourceView<NameView>: View where NameView: View {
	let viewState: PoolUnitResourceViewState
	let nameView: NameView

	init(
		viewState: PoolUnitResourceViewState,
		@ViewBuilder nameView: () -> NameView
	) {
		self.viewState = viewState
		self.nameView = nameView()
	}

	var body: some View {
		HStack(spacing: .small1) {
			TokenThumbnail(
				viewState.thumbnail,
				size: .small
			)

			HStack {
				nameView

				Spacer()

				Text(viewState.tokenAmount)
					.foregroundColor(.app.gray1)
					.textStyle(.secondaryHeader)
			}

			Spacer()

			if let isSelected = viewState.isSelected {
				CheckmarkView(appearance: .dark, isChecked: isSelected)
			}
		}
	}
}

// MARK: - PoolUnitResourcesView
struct PoolUnitResourcesView: View {
	let resources: NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>>

	var body: some View {
		let strokeColor = Color.app.gray4

		VStack(spacing: 1) {
			ForEach(resources) { resource in
				PoolUnitResourceView(viewState: resource) {
					Text(resource.symbol)
						.foregroundColor(.app.gray1)
						.textStyle(.body2HighImportance)
				}
			}
			.padding(.medium3)
			.background(.app.white)
		}
		.background(strokeColor)
		.overlay(
			RoundedRectangle(cornerRadius: .small1)
				.stroke(strokeColor, lineWidth: 1)
		)
	}
}
