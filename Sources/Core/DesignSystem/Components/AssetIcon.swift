import Resources
import SwiftUI

public struct AssetIcon: View {
	private let asset: ImageAsset
	private let hitTargetSize: HitTargetSize
	private let cornerRadius: CGFloat

	public init(asset: ImageAsset, verySmall: Bool = true) {
		self.asset = asset
		self.hitTargetSize = verySmall ? .verySmall : .small
		self.cornerRadius = verySmall ? .small3 : .small2
	}

	public var body: some View {
		Image(asset: asset)
			.frame(hitTargetSize)
			.cornerRadius(cornerRadius)
	}
}
