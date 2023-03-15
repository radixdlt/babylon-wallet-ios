import FeaturePrelude

// MARK: - PersonaList.View
extension PersonaList {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PersonaList>

		public init(store: StoreOf<PersonaList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ScrollView {
				Text(L10n.PersonaList.subtitle)
					.foregroundColor(.app.gray2)
					.textStyle(.body1HighImportance)
					.flushedLeft
					.padding([.horizontal, .top], .medium3)
					.padding(.bottom, .small2)

				Separator()

				VStack(alignment: .leading) {
					ForEachStore(
						store.scope(
							state: \.personas,
							action: { .child(.persona(id: $0, action: $1)) }
						),
						content: {
							Persona.View(store: $0)
								.padding(.vertical, .small3)
						}
					)
				}
				.padding(.horizontal, .small1)
			}
			.navigationTitle(L10n.PersonaList.title)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Personas_Preview
struct Personas_Preview: PreviewProvider {
	static var previews: some View {
		PersonaList.View(
			store: .init(
				initialState: .previewValue,
				reducer: PersonaList()
			)
		)
	}
}

extension PersonaList.State {
	public static let previewValue: Self = .init()
}
#endif
