import SwiftUI

extension View {
	@ViewBuilder
	public func loadable<T>(_ loadable: Loadable<T>,
	                        @ViewBuilder loadingView: () -> some View,
	                        @ViewBuilder successContent: (T) -> some View) -> some View
	{
		switch loadable {
		case .idle, .loading:
			loadingView()
		case let .success(value):
			successContent(value)
		case let .failure(error):
			fatalError()
		}
	}

	@ViewBuilder
	public func loadable<T>(_ loadable: Loadable<T>,
	                        @ViewBuilder successContent: (T) -> some View) -> some View
	{
		self.loadable(
			loadable,
			loadingView: {
				Spacer()
					.frame(height: .large1)
					.background(.app.gray4)
					.shimmer(active: true, config: .accountResourcesLoading)
					.cornerRadius(.small1)
			},
			successContent: successContent
		)
	}
}
