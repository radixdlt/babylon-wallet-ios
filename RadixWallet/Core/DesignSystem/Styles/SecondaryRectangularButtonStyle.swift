// MARK: - SecondaryRectangularButtonStyle
public struct SecondaryRectangularButtonStyle: ButtonStyle {
	@Environment(\.controlState) var controlState
	let backgroundColor: Color
	let shouldExpand: Bool
	let isDestructive: Bool
	let isInToolbar: Bool
	let image: Image?
	let trailingImage: Image?

	public func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		ZStack {
			HStack(spacing: .small2) {
				image
				configuration.label
				trailingImage
			}
			.foregroundColor(foregroundColor)
			.font(.app.body1Header)
			.frame(height: isInToolbar ? .toolbarButtonHeight : .standardButtonHeight)
			.frame(maxWidth: shouldExpand ? .infinity : nil)
			.padding(.horizontal, isInToolbar ? .small1 : .medium1)
			.background(backgroundColor)
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
			isDestructive ? .app.red1 : .app.gray1
		case .loading:
			.clear
		case .disabled:
			.app.gray3
		}
	}
}

extension ButtonStyle where Self == SecondaryRectangularButtonStyle {
	public static var secondaryRectangular: Self { .secondaryRectangular() }

	public static func secondaryRectangular(
		backgroundColor: Color = .app.gray4,
		shouldExpand: Bool = false,
		isDestructive: Bool = false,
		isInToolbar: Bool = false,
		image: Image? = nil,
		trailingImage: Image? = nil
	) -> Self {
		Self(
			backgroundColor: backgroundColor,
			shouldExpand: shouldExpand,
			isDestructive: isDestructive,
			isInToolbar: isInToolbar,
			image: image,
			trailingImage: trailingImage
		)
	}
}
