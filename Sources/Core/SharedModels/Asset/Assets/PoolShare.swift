import EngineToolkitModels
import Prelude
import ProfileModels

// MARK: - PoolShare
public struct PoolShare: Asset {
	public let componentAddress: ComponentAddress

	public init(
		componentAddress: ComponentAddress
	) {
		self.componentAddress = componentAddress
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
