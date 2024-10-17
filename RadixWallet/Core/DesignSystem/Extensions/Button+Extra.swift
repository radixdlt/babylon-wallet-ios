
extension Button where Label == SwiftUI.Label<Text, Image> {
	init(_ titleKey: LocalizedStringKey, asset: ImageAsset, action: @escaping () -> Void) {
		self.init(action: action) {
			SwiftUI.Label(titleKey, asset: asset)
		}
	}

	init(_ title: some StringProtocol, asset: ImageAsset, action: @escaping () -> Void) {
		self.init(action: action) {
			SwiftUI.Label(title, asset: asset)
		}
	}

	init(_ title: some StringProtocol, image: ImageResource, action: @escaping () -> Void) {
		self.init(action: action) {
			SwiftUI.Label(title, image: image)
		}
	}
}
