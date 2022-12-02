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

private extension PrimaryTextButtonStyle {
	var foregroundColor: Color {
		if isEnabled {
			return isDestructive ? .app.red1 : .app.blue2
		} else {
			return .app.gray3
		}
	}
}

public extension ButtonStyle where Self == PrimaryTextButtonStyle {
	static func primaryText(isDestructive: Bool = false) -> Self {
		Self(isDestructive: isDestructive)
	}
}
