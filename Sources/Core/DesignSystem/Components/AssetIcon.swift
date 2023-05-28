import Resources
import SwiftUI

public struct AssetIcon: View {
	private let image: Image
	private let hitTargetSize: HitTargetSize
	private let cornerRadius: CGFloat

	public enum Content {
		case asset(ImageAsset)
		case systemImage(String)
	}

	public init(_ content: Content, verySmall: Bool = true) {
		switch content {
		case let .asset(asset):
			self.image = Image(asset: asset)
		case let .systemImage(systemName):
			self.image = Image(systemName: systemName)
		}
		self.hitTargetSize = verySmall ? .verySmall : .small
		self.cornerRadius = verySmall ? .small3 : .small2
	}

	public var body: some View {
		image
			.frame(hitTargetSize)
			.cornerRadius(cornerRadius)
	}
}
