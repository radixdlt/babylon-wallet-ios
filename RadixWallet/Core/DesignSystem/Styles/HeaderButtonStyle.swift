extension ButtonStyle where Self == HeaderButtonStyle {
	static var header: HeaderButtonStyle { .init() }
}

// MARK: - HeaderButtonStyle
struct HeaderButtonStyle: ButtonStyle {
	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		configuration.label
			.textStyle(.body1Header)
			.frame(maxWidth: .infinity)
			.foregroundColor(.white)
			.frame(height: .standardButtonHeight)
			.background(.backgroundTransparent)
			.cornerRadius(.large2)
			.opacity(configuration.isPressed ? 0.4 : 1)
	}
}
