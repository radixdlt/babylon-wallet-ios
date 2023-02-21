import Resources
import SwiftUI

// MARK: - CheckmarkView
public struct CheckmarkView: View {
	public enum Appearance {
		case light
		case dark
	}

	public let appearance: Appearance
	public var isChecked: Bool

	public init(
		appearance: Appearance,
		isChecked: Bool
	) {
		self.appearance = appearance
		self.isChecked = isChecked
	}
}

extension CheckmarkView {
	public var body: some View {
		let resource: ImageAsset = {
			switch (appearance, isChecked) {
			case (.light, true):
				return AssetResource.checkmarkLightSelected
			case (.light, false):
				return AssetResource.checkmarkLightUnselected
			case (.dark, true):
				return AssetResource.checkmarkDarkSelected
			case (.dark, false):
				return AssetResource.checkmarkDarkUnselected
			}
		}()

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
