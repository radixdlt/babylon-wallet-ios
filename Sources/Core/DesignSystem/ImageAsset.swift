import Resources

extension ImageAsset: Equatable {
	public static func == (lhs: ImageAsset, rhs: ImageAsset) -> Bool {
		lhs.name == rhs.name
	}
}
