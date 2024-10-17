import SwiftUI

// MARK: - BlueButtonStyle

extension ButtonStyle where Self == BlueTextButtonStyle {
	static var blueText: BlueTextButtonStyle { .init() }
}

// MARK: - BlueTextButtonStyle
struct BlueTextButtonStyle: ButtonStyle {
	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		configuration.label
			.textStyle(.body1StandaloneLink)
			.foregroundColor(.app.blue2)
			.opacity(configuration.isPressed ? 0.5 : 1)
	}
}
