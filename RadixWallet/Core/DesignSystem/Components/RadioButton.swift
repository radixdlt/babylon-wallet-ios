// MARK: - RadioButton
public struct RadioButton: View {
	public enum State {
		case unselected
		case selected
		case disabled
	}

	public enum Appearance {
		case light
		case dark
	}

	public let appearance: Appearance
	public var state: State

	public init(
		appearance: Appearance,
		state: State
	) {
		self.appearance = appearance
		self.state = state
	}
}

extension RadioButton {
	public var body: some View {
		let resource: ImageAsset = switch (appearance, state) {
		case (.light, .unselected):
			AssetResource.radioButtonLightUnselected
		case (.light, .selected):
			AssetResource.radioButtonLightSelected
		case (.light, .disabled):
			AssetResource.radioButtonLightDisabled
		case (.dark, .unselected):
			AssetResource.radioButtonDarkUnselected
		case (.dark, .selected):
			AssetResource.radioButtonDarkSelected
		case (.dark, .disabled):
			AssetResource.radioButtonDarkDisabled
		}

		return Image(asset: resource)
			.padding(.leading, .small1)
	}
}

// MARK: - RadioButton_Previews
struct RadioButton_Previews: PreviewProvider {
	static var previews: some View {
		ZStack {
			Color.green

			RadioButton(
				appearance: .dark,
				state: .unselected
			)
		}
		.frame(.medium)
	}
}
