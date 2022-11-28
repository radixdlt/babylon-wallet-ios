import SwiftUI

// MARK: - PrimaryTextButtonStyle
public struct PrimaryTextButtonStyle: ButtonStyle {
	@Environment(\.isEnabled) var isEnabled: Bool
	let isDestructive: Bool

	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.foregroundColor(isEnabled ? (isDestructive ? .app.red1 : .app.blue2) : Color.app.gray3)
			.font(.app.body1StandaloneLink)
			.brightness(configuration.isPressed ? -0.3 : 0)
	}
}

public extension ButtonStyle where Self == PrimaryTextButtonStyle {
	static func primaryText(isDestructive: Bool = false) -> Self {
		Self(isDestructive: isDestructive)
	}
}
