import Resources
import SharedModels

public extension FungibleToken {
	func placeholderImage(xrd: Bool) -> ImageAsset {
		if xrd {
			return AssetResource.xrd
		} else {
			return AssetResource.fungibleToken
		}
	}
}
