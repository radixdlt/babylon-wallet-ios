import SwiftUI

// MARK: - ArculusCreatePIN.View
extension ArculusCreatePIN {
	struct View: SwiftUI.View {
		@FocusState private var isFocused: Bool
		@Perception.Bindable var store: StoreOf<ArculusCreatePIN>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .medium3) {
					TextField("", text: $store.inputText.sending(\.view.enteredPINUpdated))
						.keyboardType(.numberPad)
						.foregroundColor(.clear)
						.background(Color.clear)
						.accentColor(.clear)
						.frame(width: .zero, height: .zero)
						.focused($isFocused)

					HStack(spacing: 12) {
						ForEach(0 ..< pinLength, id: \.self) { index in
							ZStack {
								RoundedRectangle(cornerRadius: 8)
									.stroke(index == store.enteredPIN.count ? .textFieldFocusedBorder : Color.textFieldBorder, lineWidth: 1)
									.frame(width: 42, height: 62)
									.background(.tertiaryBackground)
								Text(index < store.enteredPIN.count ? "*" : "")
							}
						}
						.contentShape(Rectangle()) // Makes the whole HStack tappable
					}

					if store.shouldConfirmPIN {
						HStack(spacing: 12) {
							ForEach(0 ..< pinLength, id: \.self) { index in
								ZStack {
									RoundedRectangle(cornerRadius: 8)
										.stroke(store.inputText.count >= 6 && index == store.confirmedPIN.count ? .textFieldFocusedBorder : Color.textFieldBorder, lineWidth: 1)
										.frame(width: 42, height: 62)
										.background(.tertiaryBackground)
									Text(index < store.confirmedPIN.count ? "*" : "")
								}
							}
							.contentShape(Rectangle()) // Makes the whole HStack tappable
						}
					}
				}
				.padding()
				.onAppear {
					isFocused = true
					store.send(.view(.appeared))
				}
			}
		}
	}
}
