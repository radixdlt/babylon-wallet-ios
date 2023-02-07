import FeaturePrelude

// MARK: - Completion.View
extension Completion {
	struct ViewState: Equatable {
		init(state: Completion.State) {
			// TODO: implement
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<Completion>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: Completion.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				// TODO: implement
				Text("Implement: Completion")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Completion_Preview
struct Completion_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		Completion.View(
			store: .init(
				initialState: .previewValue,
				reducer: Completion()
			)
		)
	}
}

extension Completion.State {
	static let previewValue: Self = .init()
}
#endif
