import EngineToolkitModels
import Prelude
import Profile

// MARK: - PoolUnit
public struct PoolUnit: Asset, Codable {
	public let resourceAddress: ResourceAddress

	public init(
		resourceAddress: ResourceAddress
	) {
		self.resourceAddress = resourceAddress
	}
}

// MARK: - PoolUnitContainer
public struct PoolUnitContainer: AssetContainer, Sendable, Hashable, Codable {
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
