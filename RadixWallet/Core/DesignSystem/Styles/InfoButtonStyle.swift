
// MARK: - InfoButtonStyle

extension ButtonStyle where Self == InfoButtonStyle {
	static func info(showIcon: Bool) -> InfoButtonStyle {
		.init(showIcon: showIcon)
	}
}

// MARK: - InfoButtonStyle
struct InfoButtonStyle: ButtonStyle {
	let showIcon: Bool

	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		Label {
			configuration.label
				.textStyle(.body1StandaloneLink)
		} icon: {
			if showIcon {
				Image(.info)
			}
		}
		.labelStyle(.titleAndIcon)
		.opacity(configuration.isPressed ? 0.2 : 1)
	}
}
