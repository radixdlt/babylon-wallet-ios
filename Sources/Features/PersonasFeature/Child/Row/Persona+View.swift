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
			Text(viewStore.displayName)
				.background(Color.yellow)
				.foregroundColor(.red)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - Persona.View.ViewState
extension Persona.View {
	struct ViewState: Equatable {
		public let displayName: String
		init(state: Persona.State) {
			// TODO: implement
			displayName = state.persona.displayName ?? "NO NAME" // FIXME: change to required propery?
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Persona_Preview

// TODO: preview fails, persona previewValue needs to be fixed
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
