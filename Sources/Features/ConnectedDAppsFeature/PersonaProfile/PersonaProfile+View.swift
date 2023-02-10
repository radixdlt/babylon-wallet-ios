import FeaturePrelude

// MARK: - View

public extension PersonaProfile {
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

public extension PersonaProfile.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: 0) {
					BodyText(L10n.PersonaProfile.body)

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

private extension PersonaProfile.State {
	var viewState: PersonaProfile.ViewState {
		.init(persona: persona)
	}
}
