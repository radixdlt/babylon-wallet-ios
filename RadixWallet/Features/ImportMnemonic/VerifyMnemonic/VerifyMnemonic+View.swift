import SwiftUI

extension VerifyMnemonic.State {
	public var viewState: VerifyMnemonic.ViewState {
		let enumeratedWords = mnemonic.words.identifiablyEnumerated()
		let wordViewStates = enumeratedWords.map { word in
			let isConfirmationWord = wordsToConfirm.contains(word)
			return VerifyMnemonic.ViewState.WordViewState(
				word: word,
				placeholder: isConfirmationWord ? "" : "•••••",
				isDisabled: !isConfirmationWord,
				displayText: {
					if let confirmationWord = enteredWords[id: word.id]?.element {
						confirmationWord
					} else {
						""
					}
				}()
			)
		}

		return .init(
			words: wordViewStates.asIdentifiable(),
			focusedField: focusedField,
			verificationFailed: invalidMnemonic
		)
	}
}

extension VerifyMnemonic {
	public struct ViewState: Sendable, Equatable {
		struct WordViewState: Sendable, Equatable, Identifiable {
			var id: OffsetIdentified<Mnemonic.Word> {
				word
			}

			let word: OffsetIdentified<Mnemonic.Word>
			let placeholder: String
			let isDisabled: Bool
			let displayText: String
		}

		let words: IdentifiedArrayOf<WordViewState>
		let focusedField: Int?
		let verificationFailed: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		@FocusState private var focusedField: Int?
		private let store: StoreOf<VerifyMnemonic>

		public init(store: StoreOf<VerifyMnemonic>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .medium1) {
						// FIXME: Strings
						Text("Confirm you have written down the seed phrase by entering the missing words below.")
							.foregroundStyle(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)

						wordsGrid(viewStore: viewStore)

						if viewStore.verificationFailed {
							// FIXME: Strings
							WarningErrorView(text: "Incorrect seed phrase", type: .error)
						}

						Button(L10n.Common.confirm) {
							viewStore.send(.confirmSeedPhraseButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
					}
					.padding(.horizontal, .medium2)
					.padding(.bottom, .large3)
				}
				.scrollIndicators(.hidden)
			}
			// FIXME: Strings
			.navigationTitle("Confirm seed phrase")
		}

		@ViewBuilder
		private func wordsGrid(viewStore: ViewStoreOf<VerifyMnemonic>) -> some SwiftUI.View {
			SwiftUI.Grid(horizontalSpacing: .small2, verticalSpacing: .medium1) {
				ForEach(Array(viewStore.words.chunks(ofCount: 3).enumerated()), id: \.offset) { _, row in
					SwiftUI.GridRow {
						ForEach(row) { wordViewState in
							VStack {
								if wordViewState.isDisabled {
									placeholderWord(wordViewState)
								} else {
									verifyWord(wordViewState, viewStore: viewStore)
								}
							}
						}
					}
				}
			}
		}

		@ViewBuilder
		private func placeholderWord(_ viewState: ViewState.WordViewState) -> some SwiftUI.View {
			AppTextField(
				primaryHeading: .init(
					text: L10n.ImportMnemonic.wordHeading(viewState.word.offset + 1),
					isProminent: true
				),
				placeholder: viewState.placeholder,
				text: .constant(viewState.displayText)
			)
			.disabled(true)
		}

		@ViewBuilder
		private func verifyWord(_ viewState: ViewState.WordViewState, viewStore: ViewStoreOf<VerifyMnemonic>) -> some SwiftUI.View {
			AppTextField(
				primaryHeading: .init(
					text: L10n.ImportMnemonic.wordHeading(viewState.word.offset + 1),
					isProminent: true
				),
				placeholder: viewState.placeholder,
				text: .init(
					get: { viewState.displayText },
					set: { viewStore.send(.wordChanged(
						.init(
							offset: viewState.word.offset,
							element: $0.lowercased().trimmingWhitespacesAndNewlines()
						))
					) }
				),
				focus: .on(
					viewState.word.offset,
					binding: viewStore.binding(
						get: \.focusedField,
						send: { .textFieldFocused($0) }
					),
					to: $focusedField
				)
			)
			.disabled(viewState.isDisabled)
			.minimumScaleFactor(0.9)
			.keyboardType(.alphabet)
			.textInputAutocapitalization(.never)
			.autocorrectionDisabled()
			.onSubmit { store.send(.view(.wordSubmitted)) }
		}
	}
}
