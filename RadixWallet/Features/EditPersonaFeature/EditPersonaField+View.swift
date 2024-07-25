import ComposableArchitecture
import SwiftUI

extension EditPersonaField.State {
	var primaryHeading: String {
		showsTitle ? behaviour.title : ""
	}

	var inputHint: Hint? {
		if let error = $input.errors?.first {
			return .error(error)
		} else if let defaultInfoHint {
			return .info(defaultInfoHint)
		}
		return nil
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
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaField>

		public init(store: StoreOf<EditPersonaField>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				AppTextField(
					primaryHeading: .init(text: viewStore.primaryHeading),
					placeholder: L10n.CreatePersona.NameNewPersona.placeholder,
					text: viewStore.validation(
						get: \.$input,
						send: { .view(.inputFieldChanged($0)) }
					),
					hint: viewStore.inputHint
				)
				.textContentType(viewStore.contentType)
				.keyboardType(viewStore.keyboardType)
				.textInputAutocapitalization(viewStore.capitalization?.rawValue)
			}
		}
	}
}
