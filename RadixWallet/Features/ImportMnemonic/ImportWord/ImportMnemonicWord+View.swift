import ComposableArchitecture
import SwiftUI

// MARK: - Single word
extension ImportMnemonicWord.State {
	var viewState: ImportMnemonicWord.ViewState {
		.init(
			isReadonlyMode: isReadonlyMode,
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
	public struct ViewState: Equatable {
		let isReadonlyMode: Bool
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
				VStack(spacing: .small3) {
					AppTextField(
						primaryHeading: .init(text: L10n.ImportMnemonic.wordHeading(viewStore.index + 1), isProminent: true),
						placeholder: "",
						text: .init(
							get: { viewStore.displayText },
							set: { viewStore.send(.wordChanged(input: $0.lowercased().trimmingWhitespacesAndNewlines())) }
						),
						hint: viewStore.hint,
						// FIXME: Bring back autofocus
						//	focus: .on(
						//		.textField,
						//		binding: viewStore.binding(
						//			get: \.focusedField,
						//			send: { .textFieldFocused($0) }
						//		),
						//		to: $focusedField
						//	),
						showClearButton: viewStore.showClearButton,
						innerAccessory: {
							if viewStore.displayValidAccessory {
								Image(asset: AssetResource.successCheckmark)
									.resizable()
									.frame(.smallest)
							}
						}
					)
					.allowsHitTesting(!viewStore.isReadonlyMode)
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

					if viewStore.hint == nil {
						Hint(viewState: .iconError(L10n.Common.invalid)) // Dummy spacer
							.opacity(0)
					}
				}
			}
		}
	}
}
