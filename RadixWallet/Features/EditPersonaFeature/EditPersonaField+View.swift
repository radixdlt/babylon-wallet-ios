import ComposableArchitecture
import SwiftUI
extension EditPersonaField {
	public struct ViewState: Equatable {
		let primaryHeading: String
		@Validation<String, String>
		var input: String?
		let inputHint: Hint?
		#if os(iOS)
		let contentType: UITextContentType?
		let keyboardType: UIKeyboardType
		let capitalization: EquatableTextInputCapitalization?
		#endif

		init(state: State) {
			self.primaryHeading = state.showsTitle ? state.behaviour.title : ""
			self._input = state.$input
			self.inputHint = (state.$input.errors?.first).map { .error($0) }
			#if os(iOS)
			self.capitalization = state.behaviour.capitalization
			self.keyboardType = state.behaviour.keyboardType
			self.contentType = state.behaviour.contentType
			#endif
		}
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaField>

		public init(store: StoreOf<EditPersonaField>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: ViewState.init, send: Action.view) { viewStore in
				AppTextField(
					primaryHeading: .init(text: viewStore.primaryHeading),
					placeholder: "",
					text: viewStore.validation(
						get: \.$input,
						send: { .inputFieldChanged($0) }
					),
					hint: viewStore.inputHint
				)
				#if os(iOS)
				.textContentType(viewStore.contentType)
				.keyboardType(viewStore.keyboardType)
				.textInputAutocapitalization(viewStore.capitalization?.rawValue)
				#endif
			}
		}
	}
}
