import FeaturePrelude

extension EditPersona.State {
	var viewState: EditPersona.ViewState {
		.init()
	}
}

// MARK: - EditPersonaDetails.View
extension EditPersona {
	public struct ViewState: Equatable {}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersona>

		public init(store: StoreOf<EditPersona>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) {
				_ in
				VStack(alignment: .leading, spacing: .medium1) {
					EditPersonaField.View(
						store: store.scope(
							state: \.labelField,
							action: { .child(.field(id: .personaLabel, action: $0)) }
						)
					)

					Separator()

					ForEachStore(
						store.scope(
							state: \.fields,
							action: { .child(.field(id: $0, action: $1)) }
						),
						content: { EditPersonaField.View(store: $0) }
					)
				}
			}
			.padding(.horizontal, .medium1)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - EditPersonaDetails_Preview
struct EditPersona_Preview: PreviewProvider {
	static var previews: some View {
		EditPersona.View(
			store: .init(
				initialState: .previewValue,
				reducer: EditPersona()
			)
		)
	}
}

extension EditPersona.State {
	public static let previewValue = Self(
		mode: .edit,
		personaLabel: NonEmptyString("RadIpsum"),
		existingFields: [
			.init(kind: .givenName, value: "Lorem"),
			.init(kind: .familyName, value: "Ipsum"),
			.init(kind: .emailAddress, value: "lorem.ipsum@example.com"),
			.init(kind: .phoneNumber, value: "555-5555"),
		]
	)
}
#endif
