import ComposableArchitecture
import SwiftUI

// MARK: - PersonaList.View
extension PersonaList {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<PersonaList>

		init(store: StoreOf<PersonaList>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(alignment: .leading, spacing: .medium3) {
						Text(L10n.Personas.subtitle)
							.textStyle(.body1Link)
							.foregroundColor(.app.gray2)

						InfoButton(.personas, label: L10n.InfoLink.Title.personas)

						PersonaListCoreView(store: store, tappable: true, showShield: true)

						Button(L10n.Personas.createNewPersona) {
							viewStore.send(.createNewPersonaButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: false))
						.padding(.vertical, .medium2)
						.centered
					}
					.padding(.medium3)
				}
				.background(Color.app.gray5)
				.radixToolbar(title: L10n.Personas.title)
			}
		}
	}
}

// MARK: - PersonaListCoreView
struct PersonaListCoreView: View {
	private let store: StoreOf<PersonaList>
	private let tappable: Bool
	private let showShield: Bool

	init(store: StoreOf<PersonaList>, tappable: Bool, showShield: Bool) {
		self.store = store
		self.tappable = tappable
		self.showShield = showShield
	}

	var body: some View {
		VStack(spacing: .medium3) {
			ForEachStore(store.scope(state: \.personas, action: \.child.persona)) {
				PersonaFeature.View(store: $0, tappable: tappable, showShield: showShield)
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
	static let previewValue: Self = .init()
}
#endif
