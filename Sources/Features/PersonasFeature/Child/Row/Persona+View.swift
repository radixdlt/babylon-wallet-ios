import FeaturePrelude

// MARK: - Persona.View
extension Persona {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Persona>

		public init(store: StoreOf<Persona>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				Card {
					viewStore.send(.tapped)
				} contents: {
					PlainListRow(title: viewStore.displayName) {
						PersonaThumbnail(viewStore.thumbnail)
					}
				}
			}
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

extension Persona.State {
	public static let previewValue: Self = .init(persona: .previewValue0)
}
#endif
