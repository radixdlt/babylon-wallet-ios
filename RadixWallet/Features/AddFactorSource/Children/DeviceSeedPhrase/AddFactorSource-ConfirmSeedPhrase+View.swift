extension AddFactorSource.ConfirmSeedPhrase {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<AddFactorSource.ConfirmSeedPhrase>
		@FocusState
		var focusField: UInt16?

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .medium1) {
						header
						wordsStack
					}
					.padding(.medium2)
				}
				.footer {
					Button(L10n.Common.confirm) {
						store.send(.view(.confirmButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
					.controlState(store.confirmButtonControlState)

					#if DEBUG
					Button("DEBUG fill") {
						store.send(.view(.debugFillTapped))
					}
					.buttonStyle(.blueText)
					#endif
				}
			}
		}

		var header: some SwiftUI.View {
			VStack(spacing: .small2) {
				Image(store.factorSourceKind.icon)
					.resizable()
					.frame(.large)

				Text(L10n.NewBiometricFactor.ConfirmSeedPhrase.title)
					.textStyle(.sheetTitle)

				Text(L10n.NewBiometricFactor.ConfirmSeedPhrase.subtitle(4))
					.textStyle(.body1Regular)
			}
			.foregroundStyle(.app.gray1)
			.multilineTextAlignment(.center)
		}

		var wordsStack: some SwiftUI.View {
			VStack(spacing: .medium3) {
				ForEachStatic(Array(store.confirmationWords.keys)) { idx in
					AppTextField(
						primaryHeading: .init(stringLiteral: L10n.NewBiometricFactor.SeedPhrase.wordLabel(Int(idx) + 1)),
						placeholder: "",
						text: .init(get: {
							store.confirmationWords[idx]!
						}, set: { word in
							store.send(.view(.wordChanged(index: idx, word: word)))
						}),
						hint: hintForWord(at: idx),
						focus: .on(
							idx,
							binding: $store.focusField.sending(\.view.focusChanged),
							to: $focusField
						)
					)
					.keyboardType(.alphabet)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
					.id(idx)
				}
			}
		}

		func hintForWord(at idx: UInt16) -> Hint.ViewState? {
			if store.wrongWordIndices.contains(idx) {
				.error(L10n.NewBiometricFactor.ConfirmSeedPhrase.incorrectWord)
			} else {
				nil
			}
		}
	}
}
