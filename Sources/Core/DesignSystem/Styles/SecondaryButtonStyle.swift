import SwiftUI

// MARK: - SecondaryButtonStyle
public struct SecondaryButtonStyle: ButtonStyle {
	@Environment(\.isEnabled) var isEnabled: Bool
	let shouldExpand: Bool

	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.foregroundColor(isEnabled ? Color.app.gray1 : Color.app.gray3)
			.font(.app.body1Header)
			.frame(height: .standardButtonHeight)
			.frame(maxWidth: shouldExpand ? .infinity : nil)
			.padding(.horizontal, .medium1)
			.background(Color.app.gray4)
			.cornerRadius(.small2)
			.brightness(configuration.isPressed ? -0.1 : 0)
	}
}

public extension ButtonStyle where Self == SecondaryButtonStyle {
	static func secondary(shouldExpand: Bool = false) -> Self {
		Self(shouldExpand: shouldExpand)
	}
}
