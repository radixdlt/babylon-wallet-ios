import FeaturePrelude

// MARK: - PoolUnitResourcesView
struct PoolUnitResourcesView: View {
	let resources: NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>>

	var body: some View {
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
		.background(.app.gray4)
		.overlay(
			RoundedRectangle(cornerRadius: .small1)
				.stroke(.app.gray4, lineWidth: 1)
		)
	}
}

// MARK: - PoolUnitResourceViewState
struct PoolUnitResourceViewState: Identifiable, Equatable {
	var id: String { symbol }

	let thumbnail: TokenThumbnail.Content
	let symbol: String
	let tokenAmount: String
}

extension PoolUnitResourceViewState {
	init(xrdAmount: String) {
		self.init(
			thumbnail: .xrd,
			symbol: "XRD", // FIXME: Strings
			tokenAmount: xrdAmount
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
		HStack(spacing: .zero) {
			TokenThumbnail(viewState.thumbnail, size: .small)
				.padding(.trailing, .small1)

			nameView
				.padding(.trailing, .small2)

			Spacer(minLength: 0)

			Text(viewState.tokenAmount)
				.foregroundColor(.app.gray1)
				.textStyle(.secondaryHeader)
		}
	}
}
