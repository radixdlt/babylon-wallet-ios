import Foundation

// MARK: - AssetTag
public enum AssetTag: Hashable, Sendable {
	case officialRadix
	case token
	case nft
	case custom(String)
}

extension AssetTag {
	public var name: String {
		switch self {
		case .officialRadix:
			return "Official Radix" // FIXME: Strings

		case .token:
			return "Token" // FIXME: Strings

		case .nft:
			return "NFT" // FIXME: Strings

		case let .custom(string):
			return string
		}
	}

	public var icon: ImageAsset {
		if case .officialRadix = self {
			return AssetResource.officialTagIcon
		} else {
			return AssetResource.tagIcon
		}
	}
}
