import SwiftUI

// MARK: - BlueButtonStyle

extension ButtonStyle where Self == BlueTextButtonStyle {
	static var blueText: Self { .blueText() }

	static func blueText(textStyle: TextStyle = .body1StandaloneLink) -> Self {
		Self(textStyle: textStyle)
	}
}

// MARK: - BlueTextButtonStyle
struct BlueTextButtonStyle: ButtonStyle {
	let textStyle: TextStyle

	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		configuration.label
			.textStyle(textStyle)
			.foregroundColor(.app.blue2)
			.opacity(configuration.isPressed ? 0.5 : 1)
	}
}
