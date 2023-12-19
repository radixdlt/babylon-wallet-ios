import ComposableArchitecture
import SwiftUI

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
						Text(L10n.Personas.subtitle)
							.sectionHeading
							.flushedLeft
							.padding([.horizontal, .top], .medium3)
							.padding(.bottom, .small2)

						Separator()
							.padding(.bottom, .small2)

						PersonaListCoreView(store: store, tappable: true, showShield: true)
					}

					Button(L10n.Personas.createNewPersona) {
						viewStore.send(.createNewPersonaButtonTapped)
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
					.padding(.horizontal, .medium3)
					.padding(.vertical, .large1)
				}
				.navigationTitle(L10n.Personas.title)
			}
		}
	}
}

// MARK: - PersonaListCoreView
public struct PersonaListCoreView: View {
	private let store: StoreOf<PersonaList>
	private let tappable: Bool
	private let showShield: Bool

	public init(store: StoreOf<PersonaList>, tappable: Bool, showShield: Bool) {
		self.store = store
		self.tappable = tappable
		self.showShield = showShield
	}

	public var body: some View {
		VStack(spacing: .medium3) {
			ForEachStore(
				store.scope(
					state: \.personas,
					action: { .child(.persona(id: $0, action: $1)) }
				)
			) {
				Persona.View(store: $0, tappable: tappable, showShield: showShield)
					.padding(.horizontal, .medium3)
			}
		}
		.task {
			store.send(.view(.task))
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - Personas_Preview
struct Personas_Preview: PreviewProvider {
	static var previews: some View {
		PersonaList.View(
			store: .init(
				initialState: .previewValue,
				reducer: PersonaList.init
			)
		)
	}
}

extension PersonaList.State {
	public static let previewValue: Self = .init()
}
#endif
