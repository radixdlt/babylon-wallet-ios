extension ButtonStyle where Self == HeaderButtonStyle {
	static var header: HeaderButtonStyle { .init() }
}

// MARK: - HeaderButtonStyle
struct HeaderButtonStyle: ButtonStyle {
	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
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
