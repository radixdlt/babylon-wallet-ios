import Cryptography
import FeaturePrelude

// MARK: - Single word
extension ImportMnemonicWord.State {
	var viewState: ImportMnemonicWord.ViewState {
		.init(
			index: id,
			displayText: value.displayText,
			autocompletionCandidates: autocompletionCandidates,
			focusedField: focusedField,
			validation: {
				if self.value.isInvalid {
					return .invalid
				} else if self.value.isValid {
					return .valid
				} else {
					return nil
				}
			}()
		)
	}
}

// MARK: - ImportMnemonicWordField
public struct ImportMnemonicWordField: Sendable, Hashable {
	public let id: ImportMnemonicWord.State.ID
}

// MARK: - Validation
enum Validation: Sendable, Hashable {
	case invalid
	case valid
}

extension ImportMnemonicWord {
	public struct ViewState: Equatable {
		let index: Int

		let displayText: String
		let autocompletionCandidates: ImportMnemonicWord.State.AutocompletionCandidates?
		let focusedField: State.Field?

		let validation: Validation?
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
				let wordAtIndex = "Word #\(viewStore.index + 1)"
				AppTextField(
					primaryHeading: wordAtIndex,
					placeholder: wordAtIndex,
					text: .init(
						get: { viewStore.displayText },
						set: { viewStore.send(.wordChanged(input: $0.lowercased())) }
					),
					hint: { () -> Hint? in
						guard let validation = viewStore.state.validation else {
							return nil
						}
						guard validation == .invalid else {
							return nil
						}
						return .error("Invalid")
					}(),
					focus: .on(
						.textField,
						binding: viewStore.binding(
							get: \.focusedField,
							send: { .textFieldFocused($0) }
						),
						to: $focusedField
					),
					showClearButton: viewStore.focusedField != nil,
					innerAccessory: {
						if viewStore.state.validation == .valid, viewStore.focusedField == nil {
							Image(systemName: "checkmark.seal.fill").foregroundColor(.app.green1)
						}
					}
				)
				.minimumScaleFactor(0.9)
				.keyboardType(.alphabet)
				.textInputAutocapitalization(.never)
				.autocorrectionDisabled()
				.toolbar {
					if let autocompletionCandidates = viewStore.autocompletionCandidates {
						ToolbarItemGroup(placement: .keyboard) {
							HStack {
								ForEach(autocompletionCandidates.candidates, id: \.self) { candidate in
									Button("\(candidate.rawValue)") {
										viewStore.send(.autocompleteWith(candidate: candidate))
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

// MARK: - Phrase

extension ImportMnemonic.State {
	var viewState: ImportMnemonic.ViewState {
		.init(mnemonic: nil, rowCount: rowCount)
	}
}

// MARK: - ImportMnemonic.View
extension ImportMnemonic {
	public struct ViewState: Equatable {
		let mnemonic: Mnemonic?
		let rowCount: Int
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportMnemonic>

		public init(store: StoreOf<ImportMnemonic>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in

				GeometryReader { geoProxy in
					ScrollView {
						LazyVGrid(
							columns: .init(
								repeating: .init(
									.adaptive(minimum: geoProxy.frame(in: .local).width / CGFloat(wordsPerRow)),
									spacing: .small2,
									alignment: .top
								),
								count: 3
							)
						) {
							ForEachStore(
								store.scope(state: \.words, action: { .child(.word(id: $0, child: $1)) }),
								content: { importMnemonicWordStore in
									VStack(spacing: 0) {
										ImportMnemonicWord.View(store: importMnemonicWordStore)
										Spacer(minLength: .medium2)
									}
								}
							)
						}
					}
				}
				.padding(.medium3)
				.footer {
					WithControlRequirements(
						viewStore.mnemonic,
						forAction: { viewStore.send(.continueButtonTapped($0)) }
					) { action in
						Button("Import mnemonic", action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ImportMnemonic_Preview
struct ImportMnemonic_Preview: PreviewProvider {
	static var previews: some View {
		ImportMnemonic.View(
			store: .init(
				initialState: .previewValue,
				reducer: ImportMnemonic()
			)
		)
	}
}

extension ImportMnemonic.State {
	public static let previewValue = Self()
}
#endif
