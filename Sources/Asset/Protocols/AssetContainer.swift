import Foundation

// MARK: - AssetContainer
public protocol AssetContainer: Identifiable, Equatable {
	associatedtype T: Asset
	var asset: T { get }
}

public extension AssetContainer {
	var id: T.ID { asset.id }
}
