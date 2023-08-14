import Foundation

// MARK: - AssetTag
public enum AssetTag: Hashable, Sendable, Codable {
	case officialRadix
	case token
	case nft
	case custom(String)
}
