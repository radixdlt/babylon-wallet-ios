import Foundation

// MARK: - Badge
public struct Badge: Asset {
	public let address: ComponentAddress

	public init(
		address: ComponentAddress
	) {
		self.address = address
	}
}

// MARK: - BadgeContainer
public struct BadgeContainer: AssetContainer {
	public typealias T = Badge
	public let asset: Badge

	/// Metadata unique to this asset.
	public var metadata: [String: String]?

	public init(
		asset: Badge,
		metadata: [String: String]?
	) {
		self.asset = asset
		self.metadata = metadata
	}
}
