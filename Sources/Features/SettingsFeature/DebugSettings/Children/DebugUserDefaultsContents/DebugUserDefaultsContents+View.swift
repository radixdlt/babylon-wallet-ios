import FeaturePrelude

extension DebugUserDefaultsContents.State {
	var viewState: DebugUserDefaultsContents.ViewState {
		.init()
	}
}

// MARK: - DebugUserDefaultsContents.View
extension DebugUserDefaultsContents {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DebugUserDefaultsContents>

		public init(store: StoreOf<DebugUserDefaultsContents>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: DebugUserDefaultsContents")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - DebugUserDefaultsContents_Preview
struct DebugUserDefaultsContents_Preview: PreviewProvider {
	static var previews: some View {
		DebugUserDefaultsContents.View(
			store: .init(
				initialState: .previewValue,
				reducer: DebugUserDefaultsContents()
			)
		)
	}
}

extension DebugUserDefaultsContents.State {
	public static let previewValue = Self()
}
#endif
