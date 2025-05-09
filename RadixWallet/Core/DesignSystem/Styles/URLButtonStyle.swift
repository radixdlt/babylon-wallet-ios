// MARK: - URLButtonStyle
struct URLButtonStyle: ButtonStyle {
	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		Label {
			configuration.label
				.textStyle(.body1HighImportance)
				.foregroundColor(.textButton)
		} icon: {
			Image(asset: AssetResource.iconLinkOut)
				.foregroundColor(.secondaryText)
		}
		.labelStyle(.trailingIcon)
	}
}

extension ButtonStyle where Self == URLButtonStyle {
	static var url: URLButtonStyle { .init() }
}
