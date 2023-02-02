import FeaturePrelude

// MARK: - PersonaRow.View
public extension PersonaRow {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<PersonaRow>

		public init(store: StoreOf<PersonaRow>) {
			self.store = store
		}
	}
}

public extension PersonaRow.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			// TODO: implement
			Text("Implement: PersonaRow")
				.background(Color.yellow)
				.foregroundColor(.red)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - PersonaRow.View.ViewState
extension PersonaRow.View {
	struct ViewState: Equatable {
		init(state: PersonaRow.State) {
			// TODO: implement
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - PersonaRow_Preview
struct PersonaRow_Preview: PreviewProvider {
	static var previews: some View {
		PersonaRow.View(
			store: .init(
				initialState: .previewValue,
				reducer: PersonaRow()
			)
		)
	}
}
#endif
