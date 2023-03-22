import FeaturePrelude

extension EditPersonaField {
	public struct ViewState: Equatable {
		let primaryHeading: String
		let secondaryHeading: String?
		@Validation<String, String>
		var input: String?
		let inputHint: AppTextFieldHint?
		#if os(iOS)
		let capitalization: EquatableTextInputCapitalization
		let keyboardType: UIKeyboardType
		#endif

		init(state: State) {
			self.primaryHeading = state.id.title
			self.secondaryHeading = state.isRequiredByDapp ? L10n.EditPersona.InputField.Heading.General.requiredByDapp : nil
			self._input = state.$input
			self.inputHint = (state.$input.errors?.first).map { .error($0) }
			#if os(iOS)
			self.capitalization = state.id.capitalization
			self.keyboardType = state.id.keyboardType
			#endif
		}
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaField>

		public init(store: StoreOf<EditPersonaField>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: ViewState.init(state:), send: { .view($0) }) { viewStore in
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
