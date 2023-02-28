import Prelude
import Profile

// MARK: - AssetContainer
public protocol AssetContainer: Sendable, Identifiable, Equatable {
	associatedtype T: Asset
	var owner: AccountAddress { get }
	var asset: T { get set }
}

extension AssetContainer {
	public var id: T.ID { asset.id }
}
