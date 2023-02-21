import EngineToolkitModels
import Prelude

// MARK: - Asset
public protocol Asset: Sendable, Hashable, Identifiable where ID == ComponentAddress {
	/// The Scrypto Component address of asset.
	var componentAddress: ComponentAddress { get }
}

extension Asset {
	public var id: ID { componentAddress }
}

// MARK: - AssetMetadata
public enum AssetMetadata {
	public enum Key: String, Sendable, Hashable {
		// common
		case name
		case description
		case icon

		// fungible-only
		case url
		case symbol
	}
}
