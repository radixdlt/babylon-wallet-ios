import Resources
import SwiftUI

// MARK: - BlueButtonStyle

extension ButtonStyle where Self == BlueButtonStyle {
	public static var blue: BlueButtonStyle { .init() }
}

// MARK: - BlueButtonStyle
public struct BlueButtonStyle: ButtonStyle {
	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.textStyle(.body1StandaloneLink)
			.foregroundColor(.app.blue2)
			.opacity(configuration.isPressed ? 0.2 : 1)
	}
}
