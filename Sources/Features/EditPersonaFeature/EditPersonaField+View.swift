import FeaturePrelude

extension EditPersonaField.State {
	var viewState: EditPersonaField.ViewState {
		.init(
			primaryHeading: {
				switch id {
				case .personaLabel: return L10n.PersonaDetails.personaLabelHeading
				case .givenName: return L10n.PersonaDetails.givenNameHeading
				case .familyName: return L10n.PersonaDetails.familyNameHeading
				case .emailAddress: return L10n.PersonaDetails.emailAddressHeading
				case .phoneNumber: return L10n.PersonaDetails.phoneNumberHeading
				}
			}(),
			secondaryHeading: isRequiredByDapp ? L10n.EditPersona.InputError.General.requiredByDapp : nil,
			input: $input,
			inputHint: ($input.errors?.first).map { .error($0) },
			capitalization: {
				switch id {
				case .personaLabel: return .words
				case .givenName: return .words
				case .familyName: return .words
				case .emailAddress: return .never
				case .phoneNumber: return .never
				}
			}(),
			keyboardType: {
				switch id {
				case .personaLabel: return .default
				case .givenName: return .namePhonePad
				case .familyName: return .namePhonePad
				case .emailAddress: return .emailAddress
				case .phoneNumber: return .phonePad
				}
			}()
		)
	}
}

extension EditPersonaField {
	public struct ViewState: Equatable {
		let primaryHeading: String
		let secondaryHeading: String?
		@Validation<String, String>
		var input: String?
		let inputHint: AppTextFieldHint?
		let capitalization: EquatableTextInputCapitalization
		let keyboardType: UIKeyboardType
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaField>

		public init(store: StoreOf<EditPersonaField>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				AppTextField(
					primaryHeading: viewStore.primaryHeading,
					secondaryHeading: viewStore.secondaryHeading,
					placeholder: "",
					text: viewStore.validation(
						get: \.$input,
						send: { .inputFieldChanged($0) }
					),
					hint: viewStore.inputHint
				)
				#if os(iOS)
				.textInputAutocapitalization(viewStore.capitalization.rawValue)
				.keyboardType(viewStore.keyboardType)
				#endif
			}
		}
	}
}
