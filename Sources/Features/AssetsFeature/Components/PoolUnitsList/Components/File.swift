import FeaturePrelude

// MARK: - PoolUnitHeaderViewState
// not here
struct PoolUnitHeaderViewState {
	let iconURL: URL
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
		HStack(spacing: .medium2) {
			NFTThumbnail(viewState.iconURL, size: .small)

			nameView

			Spacer()
		}
	}
}
