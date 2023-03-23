import FeaturePrelude

extension EditPersonaField {
	public struct ViewState: Equatable {
		let primaryHeading: String
		let secondaryHeading: String?
		@Validation<String, String>
		var input: String?
		let inputHint: AppTextFieldHint?
		#if os(iOS)
		let contentType: UITextContentType?
		let keyboardType: UIKeyboardType
		let capitalization: EquatableTextInputCapitalization?
		#endif
		let isDynamic: Bool
		let canBeDeleted: Bool

		init(state: State) {
			self.primaryHeading = state.id.title
			self.secondaryHeading = {
				if state.kind == .dynamic(isRequiredByDapp: true) {
					return L10n.EditPersona.InputField.Heading.General.requiredByDapp
				} else {
					return nil
				}
			}()
			self._input = state.$input
			self.inputHint = (state.$input.errors?.first).map { .error($0) }
			#if os(iOS)
			self.capitalization = state.id.capitalization
			self.keyboardType = state.id.keyboardType
			self.contentType = state.id.contentType
			#endif
			self.isDynamic = state.kind.isDynamic
			self.canBeDeleted = {
				switch state.kind {
				case .static:
					return false
				case let .dynamic(isRequiredByDapp):
					return !isRequiredByDapp
				}
			}()
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
				) {
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
				#if os(iOS)
				.textContentType(viewStore.contentType)
				.keyboardType(viewStore.keyboardType)
				.textInputAutocapitalization(viewStore.capitalization?.rawValue)
				#endif
			}
		}
	}
}
