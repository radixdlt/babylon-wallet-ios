import Foundation

// MARK: - Asset
public protocol Asset: Equatable, Identifiable where ID == ComponentAddress {
	/// The Scrypto Component address of asset.
	var address: ComponentAddress { get }
}

public extension Asset {
	var id: ID { address }
}
