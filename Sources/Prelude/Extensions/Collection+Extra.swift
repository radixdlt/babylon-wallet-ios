import IdentifiedCollections

extension Collection {
	public var nilIfEmpty: Self? {
		isEmpty ? nil : self
	}
}

extension Optional where Wrapped: Collection {
	public var isNilOrEmpty: Bool {
		self == nil || self?.isEmpty == true
	}
}

extension Collection {
	public func sorted<Value: Comparable>(
		by keyPath: KeyPath<Element, Value>,
		_ comparator: (Value, Value) -> Bool = (<)
	) -> [Element] {
		sorted {
			comparator($0[keyPath: keyPath], $1[keyPath: keyPath])
		}
	}
}

extension IdentifiedArray {
	/// Add or remove the given element
	public mutating func toggle(_ element: Element) {
		if contains(element) {
			remove(element)
		} else {
			append(element)
		}
	}
}
