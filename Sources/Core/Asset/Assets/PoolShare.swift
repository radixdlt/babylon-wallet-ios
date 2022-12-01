import Foundation
import Profile

// MARK: - PoolShare
public struct PoolShare: Asset {
	public let address: ComponentAddress

	public init(
		address: ComponentAddress
	) {
		self.address = address
	}
}

// MARK: - PoolShareContainer
public struct PoolShareContainer: AssetContainer {
	public var owner: AccountAddress
	public typealias T = PoolShare
	public var asset: PoolShare

	/// Metadata unique to this asset.
	public var metadata: [String: String]?

	public init(
		owner: AccountAddress,
		asset: PoolShare,
		metadata: [String: String]?
	) {
		self.owner = owner
		self.asset = asset
		self.metadata = metadata
	}
}
