
extension Button where Label == SwiftUI.Label<Text, Image> {
	public init(_ titleKey: LocalizedStringKey, asset: ImageAsset, action: @escaping () -> Void) {
		self.init(action: action) {
			SwiftUI.Label(titleKey, asset: asset)
		}
	}

	public init(_ title: some StringProtocol, asset: ImageAsset, action: @escaping () -> Void) {
		self.init(action: action) {
			SwiftUI.Label(title, asset: asset)
		}
	}
}
