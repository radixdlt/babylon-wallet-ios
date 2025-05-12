// MARK: - PrimaryTextButtonStyle
struct PrimaryTextButtonStyle: ButtonStyle {
	@Environment(\.isEnabled) var isEnabled: Bool
	let isDestructive: Bool
	let height: CGFloat?

	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		configuration.label
			.foregroundColor(foregroundColor)
			.font(.app.body1StandaloneLink)
			.brightness(configuration.isPressed ? -0.3 : 0)
			.frame(height: height)
	}
}

extension PrimaryTextButtonStyle {
	private var foregroundColor: Color {
		if isEnabled {
			isDestructive ? .error : Color.textButton
		} else {
			.app.gray3
		}
	}
}

extension ButtonStyle where Self == PrimaryTextButtonStyle {
	static func primaryText(isDestructive: Bool = false, height: CGFloat? = nil) -> Self {
		Self(isDestructive: isDestructive, height: height)
	}
}
