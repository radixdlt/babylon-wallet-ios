
extension Array where Element: Identifiable {
	/// Returns an `IdentifiedArray` of the `Element`, omitting clashing elements
	public func asIdentifiable() -> IdentifiedArrayOf<Element> {
		var array: IdentifiedArrayOf<Element> = []
		array.append(contentsOf: self)
		return array
	}
}

extension Array {
	var nonEmpty: NonEmpty<Self>? {
		.init(self)
	}
}
