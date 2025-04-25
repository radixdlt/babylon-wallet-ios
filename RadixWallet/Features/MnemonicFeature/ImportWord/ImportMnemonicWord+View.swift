import ComposableArchitecture
import SwiftUI

// MARK: - Single word
extension ImportMnemonicWord.State {
	var viewState: ImportMnemonicWord.ViewState {
		.init(
			index: id,
			displayText: value.text,
			autocompletionCandidates: autocompletionCandidates,
			focusedField: focusedField,
			// Need to disable, since broken in swiftformat 0.52.7
			// swiftformat:disable redundantClosure
			validation: {
				if value.hasFailedValidation {
					.invalid
				} else if value.isComplete {
					.valid
				} else {
					nil
				}
			}()
			// swiftformat:enable redundantClosure
		)
	}
}

// MARK: - MnemonicValidation
enum MnemonicValidation: Sendable, Hashable {
	case invalid
	case valid
}

extension ImportMnemonicWord {
	struct ViewState: Equatable {
		let index: Int
		let displayText: String
		let autocompletionCandidates: ImportMnemonicWord.State.AutocompletionCandidates?
		let focusedField: State.Field?

		let validation: MnemonicValidation?

		var hint: Hint.ViewState? {
			guard let validation, validation == .invalid else {
				return nil
			}
			return .iconError(L10n.Common.invalid)
		}

		var showClearButton: Bool {
			focusedField != nil
		}

		var displayValidAccessory: Bool {
			validation == .valid && focusedField == nil
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		@FocusState private var focusedField: State.Field?
		private let store: StoreOf<ImportMnemonicWord>

		init(store: StoreOf<ImportMnemonicWord>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: Constants.appTextFieldSpacing) {
					AppTextField(
						primaryHeading: .init(text: L10n.ImportMnemonic.wordHeading(viewStore.index + 1), isProminent: true),
						placeholder: "",
						text: .init(
							get: { viewStore.displayText },
							set: { viewStore.send(.wordChanged(input: $0.lowercased().trimmingWhitespacesAndNewlines())) }
						),
						hint: viewStore.hint,
						focus: .on(
							State.Field.textField,
							binding: viewStore.binding(
								get: \.focusedField,
								send: ViewAction.focusChanged
							),
							to: $focusedField
						),
						showClearButton: viewStore.showClearButton,
						preventScreenshot: true,
						innerAccessory: {
							if viewStore.displayValidAccessory {
								Image(asset: AssetResource.successCheckmark)
									.resizable()
									.frame(.smallest)
							}
						}
					)
					.minimumScaleFactor(0.9)
					.keyboardType(.alphabet)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
					.toolbar {
						// We only display the currently selected textfields candidates
						if let autocompletionCandidates = viewStore.autocompletionCandidates, viewStore.focusedField != nil {
							ToolbarItemGroup(placement: .keyboard) {
								ScrollView(.horizontal, showsIndicators: false) {
									HStack {
										ForEach(autocompletionCandidates.candidates, id: \.self) { candidate in
											Button(candidate.word) {
												viewStore.send(.userSelectedCandidate(candidate))
											}
											.buttonStyle(.primaryRectangular(height: .toolbarButtonHeight))
										}
									}
								}
								.mask {
									Rectangle()
										.fill()
										.frame(height: .toolbarButtonHeight)
										.cornerRadius(.small2)
								}
							}
						}
					}
					.submitLabel(.next)
					.onSubmit {
						viewStore.send(.onSubmit)
					}

					if viewStore.hint == nil {
						Hint(viewState: .iconError(L10n.Common.invalid)) // Dummy spacer
							.opacity(0)
					}
				}
			}
		}
	}
}
