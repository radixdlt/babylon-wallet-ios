import FeaturePrelude

extension Persona.State {
	var viewState: Persona.ViewState {
		.init(displayName: persona.displayName.rawValue)
	}
}

// MARK: - Persona.View
extension Persona {
	public struct ViewState: Equatable {
		public let displayName: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Persona>

		public init(store: StoreOf<Persona>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				Button {
					viewStore.send(.editButtonTapped)
				} label: {
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
					.padding(.medium2)
					.background(Color.app.gray5)
					.cornerRadius(.small1)
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
