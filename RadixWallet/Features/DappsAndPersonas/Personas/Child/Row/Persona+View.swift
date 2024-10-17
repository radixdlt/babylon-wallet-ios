import ComposableArchitecture
import SwiftUI

// MARK: - PersonaFeature.View
extension PersonaFeature {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<PersonaFeature>
		private let tappable: Bool
		private let showShield: Bool

		init(store: StoreOf<PersonaFeature>, tappable: Bool, showShield: Bool) {
			self.store = store
			self.tappable = tappable
			self.showShield = showShield
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				if tappable {
					Card {
						viewStore.send(.tapped)
					} contents: {
						VStack(spacing: .zero) {
							PlainListRow(context: .dappAndPersona, title: viewStore.displayName) {
								Thumbnail(.persona, url: viewStore.thumbnail)
							}
							if showShield {
								EntitySecurityProblemsView(config: viewStore.securityProblemsConfig) {
									viewStore.send(.securityProblemsTapped)
								}
								.padding(.horizontal, .medium1)
								.padding(.bottom, .small1)
							}
						}
					}
				} else {
					Card {
						PlainListRow(context: .dappAndPersona, title: viewStore.displayName, accessory: nil) {
							Thumbnail(.persona, url: viewStore.thumbnail)
						}
					}
				}
			}
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - Persona_Preview

// TODO: preview fails, persona previewValue needs to be fixed
struct Persona_Preview: PreviewProvider {
	static var previews: some View {
		PersonaFeature.View(
			store: .init(
				initialState: .previewValue,
				reducer: PersonaFeature.init
			),
			tappable: true,
			showShield: true
		)
	}
}

extension PersonaFeature.State {
	static let previewValue: Self = .init(persona: .previewValue0, problems: [])
}
#endif
