import Resources
import SwiftUI

extension Button where Label == Image {
	public init(asset: ImageAsset, action: @escaping () -> Void) {
		self.init(action: action) {
			Image(asset: asset)
		}
	}
}
