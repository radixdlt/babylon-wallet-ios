import EngineToolkitModels
import Prelude

// MARK: - Asset
public protocol Asset: Sendable, Hashable, Identifiable {
	/// The Scrypto Component address of asset.
	var resourceAddress: ResourceAddress { get }
}

extension Asset {
	public var id: ResourceAddress { resourceAddress }
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
