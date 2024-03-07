import SwiftUI

// MARK: - BlueButtonStyle

extension ButtonStyle where Self == BlueTextButtonStyle {
	public static var blueText: BlueTextButtonStyle { .init() }
}

// MARK: - BlueTextButtonStyle
public struct BlueTextButtonStyle: ButtonStyle {
	public func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		configuration.label
			.textStyle(.body1StandaloneLink)
			.foregroundColor(.app.blue2)
			.opacity(configuration.isPressed ? 0.2 : 1)
	}
}
