import EditPersonaFeature
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
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					ScrollView {
						Text(L10n.PersonaList.subtitle)
							.sectionHeading
							.flushedLeft
							.padding([.horizontal, .top], .medium3)
							.padding(.bottom, .small2)

						Separator()
							.padding(.bottom, .small2)

						PersonaListCoreView(store: store)
					}

					Button(L10n.Personas.createNewPersonaButtonTitle) {
						viewStore.send(.createNewPersonaButtonTapped)
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
					.padding(.horizontal, .medium3)
					.padding(.vertical, .large1)
				}
				.navigationTitle(L10n.PersonaList.title)
			}
		}
	}
}

// MARK: - PersonaListCoreView
public struct PersonaListCoreView: View {
	private let store: StoreOf<PersonaList>

	public init(store: StoreOf<PersonaList>) {
		self.store = store
	}

	public var body: some View {
		VStack(spacing: .medium3) {
			ForEachStore(
				store.scope(
					state: \.personas,
					action: { .child(.persona(id: $0, action: $1)) }
				)
			) {
				Persona.View(store: $0)
					.padding(.horizontal, .medium3)
			}
		}
		.task {
			ViewStore(store).send(.view(.task))
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
