
extension Label where Title == Text, Icon == Image {
	public init(_ titleKey: LocalizedStringKey, asset: ImageAsset) {
		self.init {
			Text(titleKey)
		} icon: {
			Image(asset: asset)
				.renderingMode(.template)
		}
	}

	public init(_ title: some StringProtocol, asset: ImageAsset) {
		self.init {
			Text(title)
		} icon: {
			Image(asset: asset)
				.renderingMode(.template)
		}
	}
}
