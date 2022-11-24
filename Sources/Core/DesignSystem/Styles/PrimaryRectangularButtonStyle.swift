import SwiftUI

// MARK: - PrimaryRectangularButtonStyle
public struct PrimaryRectangularButtonStyle: ButtonStyle {
	@Environment(\.isEnabled) var isEnabled: Bool

	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.foregroundColor(isEnabled ? .app.white : Color.app.gray3)
			.font(.app.body1Header)
			.frame(maxWidth: .infinity)
			.frame(height: .standardButtonHeight)
			.background(isEnabled ? Color.app.blue2 : Color.app.gray4)
			.cornerRadius(.small2)
			.brightness(configuration.isPressed ? -0.1 : 0)
	}
}

public extension ButtonStyle where Self == PrimaryRectangularButtonStyle {
	static var primaryRectangular: Self { Self() }
}
