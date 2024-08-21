// MARK: - RadioButton
public struct RadioButton: View {
	public enum State {
		case unselected
		case selected
	}

	public enum Appearance {
		case light
		case dark
	}

	public let appearance: Appearance
	public let state: State
	public let isDisabled: Bool

	public init(
		appearance: Appearance,
		state: State,
		disabled: Bool = false
	) {
		self.appearance = appearance
		self.state = state
		self.isDisabled = disabled
	}
}

extension RadioButton {
	public var body: some View {
		let resource: ImageAsset = switch (appearance, state, isDisabled) {
		case (.light, .unselected, false):
			AssetResource.radioButtonLightUnselected
		case (.light, .selected, false):
			AssetResource.radioButtonLightSelected
		case (.light, .selected, true):
			AssetResource.radioButtonLightDisabled
		case (.light, .unselected, true):
			AssetResource.radioButtonLightDisabledUnselected
		case (.dark, .unselected, false):
			AssetResource.radioButtonDarkUnselected
		case (.dark, .selected, false):
			AssetResource.radioButtonDarkSelected
		case (.dark, .selected, true):
			AssetResource.radioButtonDarkDisabled
		case (.dark, .unselected, true):
			AssetResource.radioButtonDarkDisabledUnselected
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
