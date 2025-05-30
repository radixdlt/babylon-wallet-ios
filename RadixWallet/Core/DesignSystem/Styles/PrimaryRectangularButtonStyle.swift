// MARK: - PrimaryRectangularButtonStyle
struct PrimaryRectangularButtonStyle: ButtonStyle {
	@Environment(\.controlState) var controlState

	let shouldExpand: Bool
	let height: CGFloat
	let isDestructive: Bool

	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		ZStack {
			configuration.label
				.lineLimit(nil)
				.foregroundColor(foregroundColor)
				.font(.app.body1Header)
				.frame(maxWidth: shouldExpand ? .infinity : nil)
				.frame(height: height)
				.padding(.horizontal, shouldExpand ? .small2 : .medium1)
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
			? isDestructive ? .error : Color.button
			: Color.tertiaryBackground
	}
}

extension PrimaryRectangularButtonStyle {
	private var foregroundColor: Color {
		switch controlState {
		case .enabled:
			.white
		case .loading:
			.clear
		case .disabled:
			Color.secondaryText
		}
	}
}

extension ButtonStyle where Self == PrimaryRectangularButtonStyle {
	static var primaryRectangular: Self { .primaryRectangular() }

	static func primaryRectangular(
		shouldExpand: Bool = true,
		height: CGFloat = .standardButtonHeight,
		isDestructive: Bool = false
	) -> Self {
		Self(shouldExpand: shouldExpand, height: height, isDestructive: isDestructive)
	}
}
