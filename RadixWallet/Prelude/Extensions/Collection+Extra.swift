
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

extension MutableCollection where Self: RandomAccessCollection {
	public mutating func sort<Value: Comparable>(
		by keyPath: KeyPath<Element, Value>,
		_ comparator: (Value, Value) -> Bool = (<)
	) {
		sort {
			comparator($0[keyPath: keyPath], $1[keyPath: keyPath])
		}
	}
}

extension IdentifiedArray {
	/// This overload will use a different overload of the inner `sort`, which will prevent a crash
	public mutating func sort<Value: Comparable>(
		by keyPath: KeyPath<Element, Value>,
		_ comparator: (Value, Value) -> Bool = (<)
	) {
		sort {
			comparator($0[keyPath: keyPath], $1[keyPath: keyPath])
		}
	}
}

extension OrderedSet where Element: Hashable {
	/// Add or remove the given element
	public mutating func toggle(_ element: Element) {
		if contains(element) {
			remove(element)
		} else {
			append(element)
		}
	}
}

extension IdentifiedArray {
	/// Add or remove the given element
	public mutating func togglePresence(of element: Element) {
		if contains(element) {
			remove(element)
		} else {
			append(element)
		}
	}
}

extension MutableCollection {
	/// Mutates in place the elements of the collection
	public mutating func mutateAll(_ mutate: (inout Self.Element) -> Void) {
		for index in indices {
			mutate(&self[index])
		}
	}
}

extension MutableCollection where Self: RangeReplaceableCollection {
	/// Filters in place the elements of the collection
	public mutating func filterInPlace(_ isIncluded: (Element) throws -> Bool) rethrows {
		var index = startIndex
		while index != endIndex {
			if try !isIncluded(self[index]) {
				remove(at: index)
			} else {
				formIndex(after: &index)
			}
		}
	}
}

extension Sequence {
	func grouped<V: Hashable>(by value: (Element) throws -> V) rethrows -> [V: [Element]] {
		try Dictionary(grouping: self, by: value)
	}
}
