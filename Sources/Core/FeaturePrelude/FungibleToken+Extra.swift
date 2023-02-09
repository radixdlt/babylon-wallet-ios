import Resources
import SharedModels

public extension ImageAsset {
	static func placeholderImage(isXRD: Bool) -> ImageAsset {
		isXRD ? AssetResource.xrd : AssetResource.fungibleToken
	}
}
