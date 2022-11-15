import SwiftUI

// MARK: - PrimaryButtonStyle
public struct PrimaryButtonStyle: ButtonStyle {
	@Environment(\.isEnabled) var isEnabled: Bool

	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.foregroundColor(isEnabled ? .app.white : Color.app.gray3)
			.font(.app.body1Header)
			.frame(maxWidth: .infinity)
			.frame(height: .standardButtonHeight)
			.background(isEnabled ? Color.app.blue2 : Color.app.gray4)
			.cornerRadius(.small2)
			.opacity(configuration.isPressed ? 0.5 : 1)
	}
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
	static var primary: Self { Self() }
}
