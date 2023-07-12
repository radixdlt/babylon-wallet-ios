import FeaturePrelude

extension EditPersonaField {
	public struct ViewState: Equatable {
		let primaryHeading: String
		let secondaryHeading: String?
		@Validation<String, String>
		var input: String?
		let inputHint: Hint?
		#if os(iOS)
		let contentType: UITextContentType?
		let keyboardType: UIKeyboardType
		let capitalization: EquatableTextInputCapitalization?
		#endif
		let isDynamic: Bool
		let canBeDeleted: Bool

		init(state: State) {
			fatalError()
			self.primaryHeading = state.id.title
			#if os(iOS)
			self.capitalization = state.id.capitalization
			self.keyboardType = state.id.keyboardType
			self.contentType = state.id.contentType
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
					primaryHeading: .init(text: viewStore.primaryHeading),
					secondaryHeading: viewStore.secondaryHeading,
					placeholder: "",
					text: viewStore.validation(
						get: \.$input,
						send: { .inputFieldChanged($0) }
					),
					hint: viewStore.inputHint,
					innerAccessory: {
						if viewStore.isDynamic {
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
