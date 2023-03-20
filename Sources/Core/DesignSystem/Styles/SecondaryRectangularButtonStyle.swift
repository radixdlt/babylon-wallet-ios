import SwiftUI

// MARK: - SecondaryRectangularButtonStyle
public struct SecondaryRectangularButtonStyle: ButtonStyle {
	@Environment(\.controlState) var controlState
	let shouldExpand: Bool
	let isDestructive: Bool
	let isInToolbar: Bool
	let image: Image?

	public func makeBody(configuration: Configuration) -> some View {
		ZStack {
			HStack(spacing: .small2) {
				image
				configuration.label
			}
			.foregroundColor(foregroundColor)
			.font(.app.body1Header)
			.frame(height: isInToolbar ? .toolbatButtonHeight : .standardButtonHeight)
			.frame(maxWidth: shouldExpand ? .infinity : nil)
			.padding(.horizontal, isInToolbar ? .small1 : .medium1)
			.background(.app.gray4)
			.cornerRadius(isInToolbar ? .small3 : .small2)
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

extension SecondaryRectangularButtonStyle {
	private var foregroundColor: Color {
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

extension ButtonStyle where Self == SecondaryRectangularButtonStyle {
	public static var secondaryRectangular: Self { .secondaryRectangular() }

	public static func secondaryRectangular(
		shouldExpand: Bool = false,
		isDestructive: Bool = false,
		isInToolbar: Bool = false,
		image: Image? = nil
	) -> Self {
		Self(
			shouldExpand: shouldExpand,
			isDestructive: isDestructive,
			isInToolbar: isInToolbar,
			image: image
		)
	}
}
