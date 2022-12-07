import SwiftUI

// MARK: - PrimaryRectangularButtonStyle
public struct PrimaryRectangularButtonStyle: ButtonStyle {
	@Environment(\.controlState) var controlState

	public func makeBody(configuration: Configuration) -> some View {
		ZStack {
			configuration.label
				.foregroundColor(foregroundColor)
				.font(.app.body1Header)
				.frame(maxWidth: .infinity)
				.frame(height: .standardButtonHeight)
				.background(controlState.isEnabled ? Color.app.blue2 : Color.app.gray4)
				.cornerRadius(.small2)
				.brightness(configuration.isPressed ? -0.1 : 0)

			if shouldShowSpinner {
				LoadingView()
					.frame(width: .medium3, height: .medium3)
			}
		}
	}

	var shouldShowSpinner: Bool {
		controlState == .loading(.local)
	}
}

private extension PrimaryRectangularButtonStyle {
	var foregroundColor: Color {
		switch controlState {
		case .enabled:
			return .app.white
		case .loading:
			return .clear
		case .disabled:
			return .app.gray3
		}
	}
}

public extension ButtonStyle where Self == PrimaryRectangularButtonStyle {
	static var primaryRectangular: Self { Self() }
}
