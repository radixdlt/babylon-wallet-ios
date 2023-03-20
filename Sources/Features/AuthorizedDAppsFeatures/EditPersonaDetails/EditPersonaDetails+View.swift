import FeaturePrelude

extension EditPersonaDetails.State {
	var viewState: EditPersonaDetails.ViewState {
		.init(
			focus: focus,
			personaLabel: $personaLabel,
			personaLabelHint: ($personaLabel.errors?.first).map { .error($0) },
			givenName: $givenName,
			givenNameHint: ($givenName.errors?.first).map { .error($0) },
			familyName: $familyName,
			familyNameHint: ($familyName.errors?.first).map { .error($0) }
		)
	}
}

// MARK: - EditPersonaDetails.View
extension EditPersonaDetails {
	public struct ViewState: Equatable {
		let focus: State.Focus?

		@Validation<String, String>
		var personaLabel: String?
		let personaLabelHint: AppTextFieldHint?

		@Validation<String, String>
		var givenName: String?
		let givenNameHint: AppTextFieldHint?

		@Validation<String, String>
		var familyName: String?
		let familyNameHint: AppTextFieldHint?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaDetails>

		@FocusState private var focus: State.Focus?

		public init(store: StoreOf<EditPersonaDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) {
				viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					AppTextField(
						heading: L10n.PersonaDetails.personaLabelHeading,
						placeholder: "",
						text: viewStore.validation(
							get: \.$personaLabel,
							send: { .personaLabelTextFieldChanged($0) }
						),
						hint: viewStore.personaLabelHint,
						focusState: $focus,
						equals: .personaLabel,
						first: viewStore.binding(
							get: \.focus,
							send: { .focusChanged($0) }
						)
					)

					Separator()

					AppTextField(
						heading: L10n.PersonaDetails.givenNameHeading,
						placeholder: "",
						text: viewStore.validation(
							get: \.$givenName,
							send: { .givenNameTextFieldChanged($0) }
						),
						hint: viewStore.givenNameHint,
						focusState: $focus,
						equals: .givenName,
						first: viewStore.binding(
							get: \.focus,
							send: { .focusChanged($0) }
						)
					)
					#if os(iOS)
					.textInputAutocapitalization(.words)
					#endif // iOS

					AppTextField(
						heading: L10n.PersonaDetails.familyNameHeading,
						placeholder: "",
						text: viewStore.validation(
							get: \.$familyName,
							send: { .familyNameTextFieldChanged($0) }
						),
						hint: viewStore.familyNameHint,
						focusState: $focus,
						equals: .familyName,
						first: viewStore.binding(
							get: \.focus,
							send: { .focusChanged($0) }
						)
					)
					#if os(iOS)
					.textInputAutocapitalization(.words)
					#endif // iOS

					//                    .keyboardType(.emailAddress)
				}
			}
			.padding(.horizontal, .medium1)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - EditPersonaDetails_Preview
struct EditPersonaDetails_Preview: PreviewProvider {
	static var previews: some View {
		EditPersonaDetails.View(
			store: .init(
				initialState: .previewValue,
				reducer: EditPersonaDetails()
			)
		)
	}
}

extension EditPersonaDetails.State {
	public static let previewValue = Self(
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
