import Resources
import SwiftUI

public struct AssetIcon: View {
	private let image: Image
	private let hitTargetSize: HitTargetSize
	private let cornerRadius: CGFloat

	public init(image: Image, verySmall: Bool = true) {
		self.image = image
		self.hitTargetSize = verySmall ? .verySmall : .small
		self.cornerRadius = verySmall ? .small3 : .small2
	}

	public init(asset: ImageAsset, verySmall: Bool = true) {
		self.init(image: Image(asset: asset), verySmall: verySmall)
	}

	public var body: some View {
		image
			.frame(hitTargetSize)
			.cornerRadius(cornerRadius)
	}
}
