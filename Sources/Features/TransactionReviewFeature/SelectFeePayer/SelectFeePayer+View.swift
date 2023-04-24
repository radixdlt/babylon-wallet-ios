import FeaturePrelude

extension SelectFeePayer.State {
	var viewState: SelectFeePayer.ViewState {
		.init()
	}
}

// MARK: - SelectFeePayer.View
extension SelectFeePayer {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SelectFeePayer>

		public init(store: StoreOf<SelectFeePayer>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: SelectFeePayer")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SelectFeePayer_Preview
struct SelectFeePayer_Preview: PreviewProvider {
	static var previews: some View {
		SelectFeePayer.View(
			store: .init(
				initialState: .previewValue,
				reducer: SelectFeePayer()
			)
		)
	}
}

extension SelectFeePayer.State {
	public static let previewValue = Self()
}
#endif
