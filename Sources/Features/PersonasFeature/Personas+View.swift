import FeaturePrelude

// MARK: - Personas.View
public extension Personas {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Personas>

		public init(store: StoreOf<Personas>) {
			self.store = store
		}
	}
}

public extension Personas.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			// TODO: implement
			Text("Implement: Personas")
				.background(Color.yellow)
				.foregroundColor(.red)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - Personas.View.ViewState
extension Personas.View {
	struct ViewState: Equatable {
		init(state: Personas.State) {
			// TODO: implement
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Personas_Preview
struct Personas_Preview: PreviewProvider {
	static var previews: some View {
		Personas.View(
			store: .init(
				initialState: .previewValue,
				reducer: Personas()
			)
		)
	}
}
#endif
