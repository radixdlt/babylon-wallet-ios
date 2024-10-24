
// MARK: - InfoButtonStyle

extension ButtonStyle where Self == InfoButtonStyle {
	static var info: InfoButtonStyle { .init() }
}

// MARK: - InfoButtonStyle
struct InfoButtonStyle: ButtonStyle {
	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		Label {
			configuration.label
				.textStyle(.body1StandaloneLink)
		} icon: {
			Image(.info)
		}
		.labelStyle(.titleAndIcon)
		.opacity(configuration.isPressed ? 0.2 : 1)
	}
}
