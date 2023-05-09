import Resources
import SwiftUI

extension Button where Label == SwiftUI.Label<Text, Image> {
	public init(_ titleKey: LocalizedStringKey, asset: ImageAsset, action: @escaping () -> Void) {
		self.init(action: action) {
			SwiftUI.Label(titleKey, asset: asset)
		}
	}

	public init<S>(_ title: S, asset: ImageAsset, action: @escaping () -> Void) where S: StringProtocol {
		self.init(action: action) {
			SwiftUI.Label(title, asset: asset)
		}
	}
}
