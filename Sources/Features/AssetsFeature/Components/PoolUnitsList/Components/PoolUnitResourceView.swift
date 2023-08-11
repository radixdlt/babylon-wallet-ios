import FeaturePrelude

// MARK: - PoolUnitResourceViewState
struct PoolUnitResourceViewState: Identifiable, Equatable {
	var id: String {
		symbol
	}

	let thumbnail: TokenThumbnail.Content
	let symbol: String
	let tokenAmount: String
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
		}
	}
}
