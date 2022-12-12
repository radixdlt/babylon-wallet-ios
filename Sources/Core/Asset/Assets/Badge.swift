import EngineToolkit
import Foundation
import Profile

// MARK: - Badge
public struct Badge: Asset {
	public let componentAddress: ComponentAddress

	public init(
		componentAddress: ComponentAddress
	) {
		self.componentAddress = componentAddress
	}
}

// MARK: - BadgeContainer
public struct BadgeContainer: AssetContainer {
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
