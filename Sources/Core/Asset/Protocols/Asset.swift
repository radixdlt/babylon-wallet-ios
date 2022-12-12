import EngineToolkit
import Foundation

// MARK: - Asset
public protocol Asset: Equatable, Identifiable where ID == ComponentAddress {
	/// The Scrypto Component address of asset.
	var componentAddress: ComponentAddress { get }
}

public extension Asset {
	var id: ID { componentAddress }
}

// MARK: - AssetMetadata
public enum AssetMetadata {
	public enum Key: String, Sendable, Hashable {
		case symbol
		case description
		case url
		case name
	}
}
