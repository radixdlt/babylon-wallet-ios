import Resources
import SwiftUI

extension Label where Title == Text, Icon == Image {
	public init(_ titleKey: LocalizedStringKey, asset: ImageAsset) {
		self.init {
			Text(titleKey)
		} icon: {
			Image(asset: asset)
				.renderingMode(.template)
		}
	}

	public init<S>(_ title: S, asset: ImageAsset) where S: StringProtocol {
		self.init {
			Text(title)
		} icon: {
			Image(asset: asset)
				.renderingMode(.template)
		}
	}
}
