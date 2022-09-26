import Foundation

// MARK: - PoolShare
public struct PoolShare: Asset {
	public let address: ComponentAddress

	init(
		address: ComponentAddress
	) {
		self.address = address
	}
}

// MARK: - PoolShareContainer
public struct PoolShareContainer: AssetContainer {
	public typealias T = PoolShare
	public let asset: PoolShare

	/// Metadata unique to this asset.
	public var metadata: [String: String]?

	public init(
		asset: PoolShare,
		metadata: [String: String]?
	) {
		self.asset = asset
		self.metadata = metadata
	}
}
