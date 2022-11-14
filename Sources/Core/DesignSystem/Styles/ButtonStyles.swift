import SwiftUI

// MARK: - PrimaryButtonStyle
public struct PrimaryButtonStyle: ButtonStyle {
	@Environment(\.isEnabled) var isEnabled: Bool
	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.font(.app.body1Header)
			.frame(maxWidth: .infinity)
			.frame(height: 50)
			.foregroundColor(.app.white)
			.background(isEnabled ? Color.app.blue2 : Color.app.gray4)
			.cornerRadius(8)
	}
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
	static var primary: Self { Self() }
}
