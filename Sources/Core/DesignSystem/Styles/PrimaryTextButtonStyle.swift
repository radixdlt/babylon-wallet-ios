import SwiftUI

// MARK: - PrimaryTextButtonStyle
public struct PrimaryTextButtonStyle: ButtonStyle {
	@Environment(\.isEnabled) var isEnabled: Bool
	let isDestructive: Bool

	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.foregroundColor(foregroundColor)
			.font(.app.body1StandaloneLink)
			.brightness(configuration.isPressed ? -0.3 : 0)
	}
}

extension PrimaryTextButtonStyle {
	private var foregroundColor: Color {
		if isEnabled {
			return isDestructive ? .app.red1 : .app.blue2
		} else {
			return .app.gray3
		}
	}
}

extension ButtonStyle where Self == PrimaryTextButtonStyle {
	public static func primaryText(isDestructive: Bool = false) -> Self {
		Self(isDestructive: isDestructive)
	}
}
