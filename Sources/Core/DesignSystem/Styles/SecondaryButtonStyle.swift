import SwiftUI

// MARK: - SecondaryButtonStyle
public struct SecondaryButtonStyle: ButtonStyle {
	@Environment(\.isEnabled) var isEnabled: Bool

	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.foregroundColor(isEnabled ? Color.app.gray1 : Color.app.gray3)
			.font(.app.body1Header)
			.frame(height: .standardButtonHeight)
			.padding(.horizontal, .medium1)
			.background(Color.app.gray4)
			.cornerRadius(.small2)
			.opacity(configuration.isPressed ? 0.5 : 1)
	}
}

public extension ButtonStyle where Self == SecondaryButtonStyle {
	static var secondary: Self { Self() }
}
