import FeaturePrelude

// MARK: - View

public extension DAppPersona {
	@MainActor
	struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	internal struct ViewState: Equatable {
		let persona: String
	}
}

// MARK: - Body

public extension DAppPersona.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: 0) {
					BodyText(L10n.DAppPersona.body)

					Separator()

					Text("A persona called \(viewStore.persona)")
						.padding(30)
						.border(.brown)
						.padding(30)
					Spacer()
				}
				.padding(.horizontal, .medium3)
			}
			.navBarTitle(viewStore.persona)
		}
	}
}

// MARK: - Extensions

private extension DAppPersona.State {
	var viewState: DAppPersona.ViewState {
		.init(persona: persona)
	}
}
