import SwiftUI

// MARK: - SecondaryRectangularButtonStyle
public struct SecondaryRectangularButtonStyle: ButtonStyle {
	@Environment(\.controlState) var controlState
	let shouldExpand: Bool
	let isDestructive: Bool
	let image: Image?

	public func makeBody(configuration: Configuration) -> some View {
		ZStack {
			HStack(spacing: .small2) {
				image
				configuration.label
			}
			.foregroundColor(foregroundColor)
			.font(.app.body1Header)
			.frame(height: .standardButtonHeight)
			.frame(maxWidth: shouldExpand ? .infinity : nil)
			.padding(.horizontal, .medium1)
			.background(Color.app.gray4)
			.cornerRadius(.small2)
			.brightness(configuration.isPressed ? -0.1 : 0)

			if shouldShowSpinner {
				LoadingView()
					.frame(width: .medium3, height: .medium3)
			}
		}
	}

	var shouldShowSpinner: Bool {
		switch controlState {
		case .loading(.local):
			return true
		default:
			return false
		}
	}
}

private extension SecondaryRectangularButtonStyle {
	var foregroundColor: Color {
		switch controlState {
		case .enabled:
			return isDestructive ? .app.red1 : .app.gray1
		case .loading:
			return .clear
		case .disabled:
			return .app.gray3
		}
	}
}

public extension ButtonStyle where Self == SecondaryRectangularButtonStyle {
	static func secondaryRectangular(
		shouldExpand: Bool = false,
		isDestructive: Bool = false,
		image: Image? = nil
	) -> Self {
		Self(
			shouldExpand: shouldExpand,
			isDestructive: isDestructive,
			image: image
		)
	}
}
