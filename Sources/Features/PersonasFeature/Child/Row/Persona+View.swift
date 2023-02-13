import FeaturePrelude

// MARK: - Persona.View
extension Persona {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Persona>

		public init(store: StoreOf<Persona>) {
			self.store = store
		}
	}
}

extension Persona.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack(alignment: .leading, spacing: .zero) {
				ZStack {
					HStack(alignment: .center) {
						Circle()
							.strokeBorder(Color.app.gray3, lineWidth: 1)
							.background(Circle().fill(Color.app.gray4))
							.frame(.small)
							.padding(.trailing, .small1)

						VStack(alignment: .leading, spacing: 4) {
							Text(viewStore.displayName)
								.foregroundColor(.app.gray1)
								.textStyle(.secondaryHeader)
						}

						Spacer()
					}
				}
				.padding(.medium2)
			}
			.background(Color.app.gray5)
			.cornerRadius(.small1)
		}
	}
}

// MARK: - Persona.View.ViewState
extension Persona.View {
	struct ViewState: Equatable {
		public let displayName: String
		init(state: Persona.State) {
			displayName = state.persona.displayName.rawValue
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
