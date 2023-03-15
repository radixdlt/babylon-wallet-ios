import EngineToolkitModels
import Prelude
import Profile

// MARK: - PoolUnit
public struct PoolUnit: Asset {
	public let componentAddress: ComponentAddress

	public init(
		componentAddress: ComponentAddress
	) {
		self.componentAddress = componentAddress
	}
}

// MARK: - PoolUnitContainer
public struct PoolUnitContainer: AssetContainer, Sendable, Hashable {
	public var owner: AccountAddress
	public typealias T = PoolUnit
	public var asset: PoolUnit

	/// Metadata unique to this asset.
	public var metadata: [String: String]?

	public init(
		owner: AccountAddress,
		asset: PoolUnit,
		metadata: [String: String]?
	) {
		self.owner = owner
		self.asset = asset
		self.metadata = metadata
	}
}
