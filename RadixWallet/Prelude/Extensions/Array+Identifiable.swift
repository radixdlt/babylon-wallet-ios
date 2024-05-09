import IdentifiedCollections
import NonEmpty

extension Array where Element: Identifiable {
	/// Returns an `IdentifiedArray` of the `Element`, omitting clashing elements
	public func asIdentified() -> IdentifiedArrayOf<Element> {
		var array: IdentifiedArrayOf<Element> = []
		for element in self {
			let (inserted, _) = array.append(element)
			assert(inserted, "The source array does not contain unique elements, id clash for \(element.id)")
		}
		return array
	}
}

extension Array {
	var nonEmpty: NonEmpty<Self>? {
		.init(self)
	}
}

extension IdentifiedArrayOf {
	var nonEmptyElements: NonEmpty<[Element]>? {
		.init(rawValue: elements)
	}
}
