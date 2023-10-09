import FeaturePrelude

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
		HStack(spacing: .zero) {
			TokenThumbnail(viewState.thumbnail, size: .small)
				.padding(.trailing, .small1)

			nameView
				.padding(.trailing, .small2)

			Spacer(minLength: 0)

			Text(viewState.tokenAmount)
				.foregroundColor(.app.gray1)
				.textStyle(.secondaryHeader)

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

// MARK: - PoolUnitResourceViewState
struct PoolUnitResourceViewState: Identifiable, Equatable {
	var id: String { symbol }

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
	init(
		xrdAmount: String,
		isSelected: Bool? = nil
	) {
		self.init(
			thumbnail: .xrd,
			symbol: Constants.xrdTokenName,
			tokenAmount: xrdAmount,
			isSelected: isSelected
		)
	}
}
