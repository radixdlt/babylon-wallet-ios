import SwiftUI

// MARK: - PrimaryRectangularButtonStyle
public struct PrimaryRectangularButtonStyle: ButtonStyle {
	@Environment(\.isEnabled) var isEnabled
	@Environment(\.loadingState.isLoading) var isLoading

	public func makeBody(configuration: Configuration) -> some View {
		ZStack {
			configuration.label
				.foregroundColor(foregroundColor)
				.font(.app.body1Header)
				.frame(maxWidth: .infinity)
				.frame(height: .standardButtonHeight)
				.background(isEnabled ? Color.app.blue2 : Color.app.gray4)
				.cornerRadius(.small2)
				.brightness(configuration.isPressed ? -0.1 : 0)

			if isLoading {
				LoadingView()
					.frame(width: .medium3, height: .medium3)
			}
		}
		.allowsHitTesting(!isLoading)
	}
}

private extension PrimaryRectangularButtonStyle {
	var foregroundColor: Color {
		if isLoading {
			return .clear
		} else if isEnabled {
			return .app.white
		} else {
			return .app.gray3
		}
	}
}

public extension ButtonStyle where Self == PrimaryRectangularButtonStyle {
	static var primaryRectangular: Self { Self() }
}
