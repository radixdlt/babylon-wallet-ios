
// MARK: - InfoButtonStyle

extension ButtonStyle where Self == InfoButtonStyle {
	public static var info: InfoButtonStyle { .init() }
}

// MARK: - InfoButtonStyle
public struct InfoButtonStyle: ButtonStyle {
	public func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		Label {
			configuration.label
				.textStyle(.body1StandaloneLink)
		} icon: {
			Image(asset: AssetResource.info)
		}
		.labelStyle(.titleAndIcon)
		.foregroundColor(.app.blue2)
		.opacity(configuration.isPressed ? 0.2 : 1)
	}
}
