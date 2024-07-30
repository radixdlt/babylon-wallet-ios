extension ButtonStyle where Self == HeaderButtonStyle {
	public static var header: HeaderButtonStyle { .init() }
}

// MARK: - HeaderButtonStyle
public struct HeaderButtonStyle: ButtonStyle {
	public func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		configuration.label
			.textStyle(.body1Header)
			.frame(maxWidth: .infinity)
			.foregroundColor(.app.white)
			.frame(height: .standardButtonHeight)
			.background(.app.whiteTransparent3)
			.cornerRadius(.large2)
			.opacity(configuration.isPressed ? 0.4 : 1)
	}
}
