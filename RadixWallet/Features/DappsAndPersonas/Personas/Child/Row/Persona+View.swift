import ComposableArchitecture
import SwiftUI

// MARK: - PersonaReducer.View
extension PersonaReducer {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PersonaReducer>
		private let tappable: Bool
		private let showShield: Bool

		public init(store: StoreOf<PersonaReducer>, tappable: Bool, showShield: Bool) {
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
						VStack {
							PlainListRow(title: viewStore.displayName) {
								Thumbnail(.persona, url: viewStore.thumbnail)
							}
							if showShield, viewStore.shouldWriteDownMnemonic {
								shieldPromptView(
									text: L10n.Personas.writeSeedPhrase,
									action: {
										viewStore.send(.writeDownSeedPhrasePromptTapped)
									}
								)
								.background(.app.gray2)
								.cornerRadius(.small2)
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

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - Persona_Preview

// TODO: preview fails, persona previewValue needs to be fixed
struct Persona_Preview: PreviewProvider {
	static var previews: some View {
		PersonaReducer.View(
			store: .init(
				initialState: .previewValue,
				reducer: PersonaReducer.init
			),
			tappable: true,
			showShield: true
		)
	}
}

extension PersonaReducer.State {
	public static let previewValue: Self = .init(persona: .previewValue0)
}
#endif
