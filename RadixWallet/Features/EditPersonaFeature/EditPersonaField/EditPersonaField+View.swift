import ComposableArchitecture
import SwiftUI

extension EditPersonaField.State {
	var primaryHeading: String? {
		showsTitle ? behaviour.title : nil
	}

	var inputHint: Hint.ViewState? {
		if let error = $input.errors?.first {
			return .iconError(error)
		} else if let defaultInfoHint {
			return .info(defaultInfoHint)
		}
		return nil
	}

	var placeholder: String {
		behaviour.placeholder
	}

	var contentType: UITextContentType? {
		behaviour.contentType
	}

	var keyboardType: UIKeyboardType {
		behaviour.keyboardType
	}

	var capitalization: EquatableTextInputCapitalization? {
		behaviour.capitalization
	}
}

// MARK: - EditPersonaField.View
extension EditPersonaField {
	struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaField>
		@FocusState private var textFieldFocus: Bool

		init(store: StoreOf<EditPersonaField>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				AppTextField(
					primaryHeading: viewStore.primaryHeading.map { .init(text: $0) },
					placeholder: viewStore.placeholder,
					text: viewStore.validation(
						get: \.$input,
						send: { .view(.inputFieldChanged($0)) }
					),
					hint: viewStore.inputHint,
					focus: .on(
						true,
						binding: viewStore.binding(
							get: \.textFieldFocused,
							send: { .view(.focusChanged($0)) }
						),
						to: $textFieldFocus
					)
				)
				.textContentType(viewStore.contentType)
				.keyboardType(viewStore.keyboardType)
				.textInputAutocapitalization(viewStore.capitalization?.rawValue)
				.autocorrectionDisabled()
			}
		}
	}
}
