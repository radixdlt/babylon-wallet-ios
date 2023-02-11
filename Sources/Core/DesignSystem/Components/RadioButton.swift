import Resources
import SwiftUI

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
		let resource: ImageAsset = {
			switch (appearance, state) {
			case (.light, .unselected):
				return AssetResource.radioButtonLightUnselected
			case (.light, .selected):
				return AssetResource.radioButtonLightSelected
			case (.light, .disabled):
				return AssetResource.radioButtonLightDisabled
			case (.dark, .unselected):
				return AssetResource.radioButtonDarkUnselected
			case (.dark, .selected):
				return AssetResource.radioButtonDarkSelected
			case (.dark, .disabled):
				return AssetResource.radioButtonDarkDisabled
			}
		}()

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
