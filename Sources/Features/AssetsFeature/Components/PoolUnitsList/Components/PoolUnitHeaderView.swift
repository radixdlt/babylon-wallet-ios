import FeaturePrelude

// MARK: - PoolUnitHeaderViewState
struct PoolUnitHeaderViewState {
	let iconURL: URL?
}

// MARK: - PoolUnitHeaderView
struct PoolUnitHeaderView<NameView>: View where NameView: View {
	let viewState: PoolUnitHeaderViewState

	let nameView: NameView

	init(
		viewState: PoolUnitHeaderViewState,
		@ViewBuilder nameView: () -> NameView
	) {
		self.viewState = viewState
		self.nameView = nameView()
	}

	var body: some View {
		HStack(spacing: .zero) {
			NFTThumbnail(viewState.iconURL, size: .small)
				.padding(.trailing, .medium2)

			nameView

			Spacer(minLength: 0)
		}
	}
}
