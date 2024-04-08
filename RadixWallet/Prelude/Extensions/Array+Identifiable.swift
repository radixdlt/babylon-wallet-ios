
extension Array where Element: Identifiable {
	/// Returns an `IdentifiedArray` of the `Element`, omitting clashing elements
	public func asIdentifiable() -> IdentifiedArrayOf<Element> {
		var array: IdentifiedArrayOf<Element> = []
		for element in self {
			let (alreadyExists, _) = array.append(element)
			if alreadyExists {
				#if DEBUG
				assertionFailure("The source array does not contain unique elements, id clash for \(element.id)")
				#endif
			}
		}
		return array
	}
}

extension Array {
	var nonEmpty: NonEmpty<Self>? {
		.init(self)
	}
}
