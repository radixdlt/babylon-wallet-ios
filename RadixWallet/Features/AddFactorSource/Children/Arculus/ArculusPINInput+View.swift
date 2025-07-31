import SwiftUI

// MARK: - ArculusCreatePIN.View
extension ArculusPINInput {
	struct View: SwiftUI.View {
		enum PinInputKind {
			case pin
			case confirmation
		}

		@FocusState private var inputFieldFocused: Bool
		@Perception.Bindable var store: StoreOf<ArculusPINInput>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .medium3) {
					TextField("", text: $store.inputText.sending(\.view.enteredPINUpdated))
						.keyboardType(.numberPad)
						.foregroundColor(.clear)
						.background(Color.clear)
						.accentColor(.clear)
						.frame(width: .zero, height: .zero)
						.focused($inputFieldFocused)

					pinInputView(text: "Enter PIN", input: store.enteredPIN, isFocused: store.inputText.count < pinLength)

					if store.shouldConfirmPIN {
						VStack(alignment: .leading) {
							pinInputView(text: "Confirm PIN", input: store.confirmedPIN, isFocused: store.inputText.count >= pinLength)
							if let hint = store.pinInvalidHint {
								Hint(viewState: hint)
							}
						}
					}
				}
				.padding()
				.onAppear {
					inputFieldFocused = true
				}
			}
		}

		@ViewBuilder
		func pinInputView(text: String, input: String.SubSequence, isFocused: Bool) -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .small3) {
				Text(text)
					.foregroundStyle(.primaryText)
					.textStyle(.body1HighImportance)
				HStack(spacing: 12) {
					ForEach(0 ..< pinLength, id: \.self) { index in
						ZStack {
							RoundedRectangle(cornerRadius: 8)
								.stroke(isFocused && index == input.count ? .textFieldFocusedBorder : .textFieldBorder, lineWidth: 1)
								.background(.textFieldBackground)
								.frame(width: 42, height: 62)
								.clipShape(RoundedRectangle(cornerRadius: 8))
							Text(index < input.count ? "*" : "")
						}
					}
				}
			}
			.contentShape(Rectangle())
			.onTapGesture {
				inputFieldFocused = true
			}
		}
	}
}
