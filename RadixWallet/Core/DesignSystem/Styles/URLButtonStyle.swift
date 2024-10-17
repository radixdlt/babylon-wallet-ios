// MARK: - URLButtonStyle
struct URLButtonStyle: ButtonStyle {
	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		Label {
			configuration.label
				.textStyle(.body1HighImportance)
				.foregroundColor(.app.blue2)
		} icon: {
			Image(asset: AssetResource.iconLinkOut)
				.foregroundColor(.app.gray2)
		}
		.labelStyle(.trailingIcon)
	}
}

extension ButtonStyle where Self == URLButtonStyle {
	static var url: URLButtonStyle { .init() }
}
