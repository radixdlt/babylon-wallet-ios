import ComposableArchitecture
import SwiftUI

// MARK: - Persona.View
extension Persona {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Persona>
		private let tappable: Bool
		private let showShield: Bool

		public init(store: StoreOf<Persona>, tappable: Bool, showShield: Bool) {
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
								PersonaThumbnail(viewStore.thumbnail)
							}
							if showShield, viewStore.shouldWriteDownMnemonic {
								shieldPromptView(
									// FIXME: Strings
									text: "Write down this Persona's seed phrase",
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
							PersonaThumbnail(viewStore.thumbnail)
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
		Persona.View(
			store: .init(
				initialState: .previewValue,
				reducer: Persona.init
			),
			tappable: true,
			showShield: true
		)
	}
}

extension Persona.State {
	public static let previewValue: Self = .init(persona: .previewValue0)
}
#endif
