import FeaturePrelude

extension FeaturesPreviewer.State {
	var viewState: FeaturesPreviewer.ViewState {
		.init()
	}
}

// MARK: - FeaturesPreviewer.View
extension FeaturesPreviewer {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FeaturesPreviewer>

		public init(store: StoreOf<FeaturesPreviewer>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: FeaturesPreviewer")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - FeaturesPreviewer_Preview
struct FeaturesPreviewer_Preview: PreviewProvider {
	static var previews: some View {
		FeaturesPreviewer.View(
			store: .init(
				initialState: .previewValue,
				reducer: FeaturesPreviewer()
			)
		)
	}
}

extension FeaturesPreviewer.State {
	public static let previewValue = Self()
}
#endif
