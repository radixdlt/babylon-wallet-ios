extension ButtonStyle where Self == HeaderButtonStyle {
	static var header: HeaderButtonStyle {
		.init()
	}
}

extension View {
	func glassToolbarIconButtonSurface() -> some View {
		modifier(GlassToolbarIconButtonSurface())
	}
}

// MARK: - HeaderButtonStyle
struct HeaderButtonStyle: ButtonStyle {
	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		configuration.label
			.textStyle(.body1Header)
			.frame(maxWidth: .infinity)
			.foregroundColor(.white)
			.frame(height: .standardButtonHeight)
			.modifier(GlassHeaderButtonBackground())
			.cornerRadius(.large2)
			.opacity(configuration.isPressed ? 0.4 : 1)
	}
}

// MARK: - GlassHeaderButtonBackground
private struct GlassHeaderButtonBackground: ViewModifier {
	func body(content: Content) -> some View {
		if #available(iOS 26, *) {
			content.glassEffect(.clear.interactive(), in: .rect(cornerRadius: .small2))
		} else {
			content
				.background(.backgroundTransparent)
		}
	}
}

// MARK: - GlassToolbarIconButtonSurface
private struct GlassToolbarIconButtonSurface: ViewModifier {
	func body(content: Content) -> some View {
		if #available(iOS 26, *) {
			content
				.background(.clear, in: Circle())
				.glassEffect(.clear.interactive(), in: .circle)
		} else {
			content
				.background(.tertiaryBackground.opacity(0.7), in: Circle())
				.overlay(Circle().stroke(.border.opacity(0.7), lineWidth: 1))
		}
	}
}
