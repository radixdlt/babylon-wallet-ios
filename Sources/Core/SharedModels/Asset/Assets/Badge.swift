import EngineToolkitModels
import Prelude
import Profile

// MARK: - Badge
public struct Badge: Asset {
	public let resourceAddress: ResourceAddress

	public init(
		resourceAddress: ResourceAddress
	) {
		self.resourceAddress = resourceAddress
	}
}

// MARK: - BadgeContainer
public struct BadgeContainer: AssetContainer, Sendable, Hashable {
	public var owner: AccountAddress
	public typealias T = Badge
	public var asset: Badge

	/// Metadata unique to this asset.
	public var metadata: [String: String]?

	public init(
		owner: AccountAddress,
		asset: Badge,
		metadata: [String: String]?
	) {
		self.owner = owner
		self.asset = asset
		self.metadata = metadata
	}
}
