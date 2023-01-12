import Asset
import Resources

public extension FungibleToken {
	var placeholderImage: ImageAsset {
		if isXRD {
			return AssetResource.xrd
		} else {
			return AssetResource.fungibleToken
		}
	}
}
