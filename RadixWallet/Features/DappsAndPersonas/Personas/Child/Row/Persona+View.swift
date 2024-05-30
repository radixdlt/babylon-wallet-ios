import ComposableArchitecture
import SwiftUI

// MARK: - PersonaFeature.View
extension PersonaFeature {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PersonaFeature>
		private let tappable: Bool
		private let showShield: Bool

		public init(store: StoreOf<PersonaFeature>, tappable: Bool, showShield: Bool) {
			self.store = store
			self.tappable = tappable
			self.showShield = showShield
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				if tappable {
					Card {
						viewStore.send(.tapped)
					} contents: {
						VStack(spacing: .zero) {
							PlainListRow(title: viewStore.displayName) {
								Thumbnail(.persona, url: viewStore.thumbnail)
							}
							if showShield {
								EntitySecurityProblems.View(store: store.entitySecurityProblems)
									.padding(.horizontal, .medium3)
									.padding(.vertical, .small2)
							}
						}
					}
				} else {
					Card {
						PlainListRow(title: viewStore.displayName, accessory: nil) {
							Thumbnail(.persona, url: viewStore.thumbnail)
						}
					}
				}
			}
		}
	}
}

private extension StoreOf<PersonaFeature> {
	var entitySecurityProblems: StoreOf<EntitySecurityProblems> {
		scope(state: \.entitySecurityProblems, action: \.child.entitySecurityProblems)
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
	public static let previewValue: Self = .init(persona: .previewValue0)
}
#endif
