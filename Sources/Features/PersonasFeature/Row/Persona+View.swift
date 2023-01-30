import FeaturePrelude

// MARK: - Persona.View
public extension Persona {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Persona>

		public init(store: StoreOf<Persona>) {
			self.store = store
		}
	}
}

public extension Persona.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			// TODO: implement
			Text("Implement: Persona")
				.background(Color.yellow)
				.foregroundColor(.red)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - Persona.View.ViewState
extension Persona.View {
	struct ViewState: Equatable {
		init(state: Persona.State) {
			// TODO: implement
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Persona_Preview
struct Persona_Preview: PreviewProvider {
	static var previews: some View {
		Persona.View(
			store: .init(
				initialState: .previewValue,
				reducer: Persona()
			)
		)
	}
}
#endif
