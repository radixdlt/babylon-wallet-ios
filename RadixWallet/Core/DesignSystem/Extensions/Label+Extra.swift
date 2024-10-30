
extension Label where Title == Text, Icon == Image {
	init(_ titleKey: LocalizedStringKey, asset: ImageAsset) {
		self.init {
			Text(titleKey)
		} icon: {
			Image(asset: asset)
				.renderingMode(.template)
		}
	}

	init(_ title: some StringProtocol, asset: ImageAsset) {
		self.init {
			Text(title)
		} icon: {
			Image(asset: asset)
				.renderingMode(.template)
		}
	}

	init(_ title: some StringProtocol, image: ImageResource) {
		self.init {
			Text(title)
		} icon: {
			Image(image)
				.renderingMode(.template)
		}
	}
}
