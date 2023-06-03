import FeaturePrelude

extension SimpleLostPhoneHelper.State {
	var viewState: SimpleLostPhoneHelper.ViewState {
		.init()
	}
}

// MARK: - SimpleLostPhoneHelper.View
extension SimpleLostPhoneHelper {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SimpleLostPhoneHelper>

		public init(store: StoreOf<SimpleLostPhoneHelper>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: SimpleLostPhoneHelper")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SimpleLostPhoneHelper_Preview
struct SimpleLostPhoneHelper_Preview: PreviewProvider {
	static var previews: some View {
		SimpleLostPhoneHelper.View(
			store: .init(
				initialState: .previewValue,
				reducer: SimpleLostPhoneHelper()
			)
		)
	}
}

extension SimpleLostPhoneHelper.State {
	public static let previewValue = Self()
}
#endif
