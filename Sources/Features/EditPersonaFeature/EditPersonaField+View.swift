import FeaturePrelude

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
		let isDeletable: Bool
		let canBeDeleted: Bool

		init(state: State) {
			self.primaryHeading = state.id.title
			self._input = state.$input
			self.inputHint = (state.$input.errors?.first).map { .error($0) }
			#if os(iOS)
			self.capitalization = state.id.capitalization
			self.keyboardType = state.id.keyboardType
			self.contentType = state.id.contentType
			#endif
			self.isDeletable = state.isDeletable
			self.canBeDeleted = !state.isRequestedByDapp
		}
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaField>

		public init(store: StoreOf<EditPersonaField>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: ViewState.init, send: Action.view) { viewStore in
				HStack {
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

					if viewStore.isDeletable {
						Button(action: { viewStore.send(.deleteButtonTapped) }) {
							Image(asset: AssetResource.trash)
								.offset(x: .small3)
								.frame(.verySmall, alignment: .trailing)
						}
						.modifier {
							if viewStore.canBeDeleted { $0 } else { $0.hidden() }
						}
					}
				}
			}
		}
	}
}
