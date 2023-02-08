import Resources
import SharedModels

public extension FungibleToken {
	func placeholderImage(isXRD: Bool) -> ImageAsset {
		isXRD ? AssetResource.xrd : AssetResource.fungibleToken
	}
}
