// MARK: - CheckmarkView
struct CheckmarkView: View {
	enum Appearance {
		case light
		case dark
	}

	let appearance: Appearance
	var isChecked: Bool

	init(
		appearance: Appearance,
		isChecked: Bool
	) {
		self.appearance = appearance
		self.isChecked = isChecked
	}
}

extension CheckmarkView {
	var body: some View {
		let resource: ImageAsset = switch (appearance, isChecked) {
		case (.light, true):
			AssetResource.checkmarkLightSelected
		case (.light, false):
			AssetResource.checkmarkLightUnselected
		case (.dark, true):
			AssetResource.checkmarkDarkSelected
		case (.dark, false):
			AssetResource.checkmarkDarkUnselected
		}

		return Image(asset: resource)
			.padding(.leading, .small1)
	}
}

// MARK: - CheckmarkView_Previews
struct CheckmarkView_Previews: PreviewProvider {
	static var previews: some View {
		ZStack {
			Color.green

			CheckmarkView(
				appearance: .light,
				isChecked: true
			)
		}
		.frame(.medium)
	}
}
