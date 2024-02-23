
extension View {
	@ViewBuilder
	public func loadable<T>(
		_ loadable: Loadable<T>,
		@ViewBuilder loadingView: () -> some View,
		@ViewBuilder errorView: (Error) -> some View = { _ in EmptyView() },
		@ViewBuilder successContent: (T) -> some View
	) -> some View {
		switch loadable {
		case .idle, .loading:
			loadingView()
		case let .success(value):
			successContent(value)
		case let .failure(error):
			errorView(error)
		}
	}

	@ViewBuilder
	public func loadable<T>(
		_ loadable: Loadable<T>,
		loadingViewHeight: CGFloat = .large1,
		@ViewBuilder successContent: (T) -> some View
	) -> some View {
		self.loadable(
			loadable,
			loadingView: {
				shimmeringLoadingView(height: loadingViewHeight)
			},
			successContent: successContent
		)
	}

	@ViewBuilder
	func shimmeringLoadingView(height: CGFloat = .large1) -> some View {
		Spacer()
			.background(.app.gray4)
			.shimmer(active: true, config: .accountResourcesLoading)
			.frame(height: height)
			.cornerRadius(.small1)
	}
}
