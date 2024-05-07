
public struct AssetIcon: View {
	private let image: Image
	private let hitTargetSize: HitTargetSize
	private let cornerRadius: CGFloat

	public enum Content: Equatable {
		case asset(ImageAsset)
		case systemImage(String)
	}

	public init(_ content: Content, verySmall: Bool = true) {
		self.init(content, size: verySmall ? .verySmall : .small)
	}

	public init(_ content: Content, size: HitTargetSize) {
		switch content {
		case let .asset(asset):
			self.image = Image(asset: asset)
		case let .systemImage(systemName):
			self.image = Image(systemName: systemName)
		}
		self.hitTargetSize = size
		self.cornerRadius = size.cornerRadius
	}

	public var body: some View {
		image
			.resizable()
			.scaledToFit()
			.frame(hitTargetSize)
			.cornerRadius(cornerRadius)
	}
}
