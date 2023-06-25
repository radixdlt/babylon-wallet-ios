import FeaturePrelude

extension SelectFactorKindThenFactor.State {
	var viewState: SelectFactorKindThenFactor.ViewState {
		.init()
	}
}

// MARK: - SelectFactorKindThenFactor.View
extension SelectFactorKindThenFactor {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SelectFactorKindThenFactor>

		public init(store: StoreOf<SelectFactorKindThenFactor>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: SelectFactorKindThenFactor")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SelectFactorKindThenFactor_Preview
struct SelectFactorKindThenFactor_Preview: PreviewProvider {
	static var previews: some View {
		SelectFactorKindThenFactor.View(
			store: .init(
				initialState: .previewValue,
				reducer: SelectFactorKindThenFactor()
			)
		)
	}
}

extension SelectFactorKindThenFactor.State {
	public static let previewValue = Self()
}
#endif
