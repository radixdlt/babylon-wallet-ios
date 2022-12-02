import SwiftUI

// MARK: - SecondaryRectangularButtonStyle
public struct SecondaryRectangularButtonStyle: ButtonStyle {
	@Environment(\.isEnabled) var isEnabled: Bool
	@Environment(\.isLoading) var isLoading: Bool
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

			if isLoading {
				LoaderView()
			}
		}
		.allowsHitTesting(!isLoading)
	}
}

private extension SecondaryRectangularButtonStyle {
	var foregroundColor: Color {
		if isLoading {
			return .clear
		} else if isEnabled {
			return isDestructive ? .app.red1 : .app.gray1
		} else {
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
