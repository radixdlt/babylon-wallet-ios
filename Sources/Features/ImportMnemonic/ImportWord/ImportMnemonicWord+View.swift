import Cryptography
import FeaturePrelude

// MARK: - Single word
extension ImportMnemonicWord.State {
	var viewState: ImportMnemonicWord.ViewState {
		.init(
			isReadonlyMode: isReadonlyMode,
			index: id,
			displayText: value.text,
			autocompletionCandidates: autocompletionCandidates,
			focusedField: focusedField,
			validation: {
				if self.value.hasFailedValidation {
					return .invalid
				} else if self.value.isComplete {
					return .valid
				} else {
					return nil
				}
			}()
		)
	}
}

// MARK: - Validation
enum Validation: Sendable, Hashable {
	case invalid
	case valid
}

extension ImportMnemonicWord {
	public struct ViewState: Equatable {
		let isReadonlyMode: Bool
		let index: Int

		let displayText: String
		let autocompletionCandidates: ImportMnemonicWord.State.AutocompletionCandidates?
		let focusedField: State.Field?

		let validation: Validation?
		var wordAtIndex: String {
			// FIXME: strings
			"word #\(index + 1)"
		}

		var hint: Hint? {
			guard let validation, validation == .invalid else {
				return nil
			}
			// FIXME: strings
			return .error("Invalid")
		}

		var showClearButton: Bool {
			focusedField != nil
		}

		var displayValidAccessory: Bool {
			!isReadonlyMode && validation == .valid && focusedField == nil
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		@FocusState private var focusedField: State.Field?
		private let store: StoreOf<ImportMnemonicWord>

		public init(store: StoreOf<ImportMnemonicWord>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				AppTextField(
					secondaryHeading: viewStore.wordAtIndex,
					placeholder: viewStore.wordAtIndex,
					text: .init(
						get: { viewStore.displayText },
						set: { viewStore.send(.wordChanged(input: $0.lowercased().trimmedInclNewlin())) }
					),
					hint: viewStore.hint,
					focus: .on(
						.textField,
						binding: viewStore.binding(
							get: \.focusedField,
							send: { .textFieldFocused($0) }
						),
						to: $focusedField
					),
					showClearButton: viewStore.showClearButton,
					innerAccessory: {
						if viewStore.displayValidAccessory {
							Image(systemName: "checkmark.seal.fill").foregroundColor(.app.green1)
						}
					}
				)
				.disabled(viewStore.isReadonlyMode)
				.minimumScaleFactor(0.9)
				.keyboardType(.alphabet)
				.textInputAutocapitalization(.never)
				.autocorrectionDisabled()
				.toolbar {
					if
						let autocompletionCandidates = viewStore.autocompletionCandidates,
						viewStore.focusedField != nil // we only display the currently selected textfields candidates
					{
						ToolbarItemGroup(placement: .keyboard) {
							ScrollView([.horizontal], showsIndicators: false) {
								HStack {
									ForEach(autocompletionCandidates.candidates, id: \.self) { candidate in
										Button("\(candidate.word.rawValue)") {
											viewStore.send(.userSelectedCandidate(candidate))
										}
										.buttonStyle(.primaryRectangular(height: .toolbarButtonHeight))
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
