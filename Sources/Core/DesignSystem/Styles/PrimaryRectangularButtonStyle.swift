import SwiftUI

// MARK: - PrimaryRectangularButtonStyle
public struct PrimaryRectangularButtonStyle: ButtonStyle {
	@Environment(\.controlState) var controlState

	let isDestructive: Bool

	public func makeBody(configuration: Configuration) -> some View {
		ZStack {
			configuration.label
				.foregroundColor(foregroundColor)
				.font(.app.body1Header)
				.frame(maxWidth: .infinity)
				.frame(height: .standardButtonHeight)
				.background(backgroundColor)
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

	var backgroundColor: Color {
		controlState.isEnabled
			? isDestructive ? .app.red1 : .app.blue2
			: .app.gray4
	}
}

extension PrimaryRectangularButtonStyle {
	private var foregroundColor: Color {
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

extension ButtonStyle where Self == PrimaryRectangularButtonStyle {
	public static var primaryRectangular: Self { .primaryRectangular() }

	public static func primaryRectangular(isDestructive: Bool = false) -> Self {
		Self(isDestructive: isDestructive)
	}
}
